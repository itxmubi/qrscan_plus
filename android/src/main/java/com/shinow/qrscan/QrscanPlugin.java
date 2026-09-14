package com.shinow.qrscan;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Build;
import android.provider.MediaStore;
import android.util.Log;

import androidx.annotation.NonNull;

import com.google.zxing.BinaryBitmap;
import com.google.zxing.EncodeHintType;
import com.google.zxing.MultiFormatReader;
import com.google.zxing.MultiFormatWriter;
import com.google.zxing.NotFoundException;
import com.google.zxing.RGBLuminanceSource;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.common.HybridBinarizer;
import com.google.zxing.integration.android.IntentIntegrator;
import com.google.zxing.integration.android.IntentResult;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

public class QrscanPlugin implements FlutterPlugin, ActivityAware, MethodCallHandler, PluginRegistry.ActivityResultListener {

    private static final String TAG = "QrscanPlugin";
    private static final int REQUEST_IMAGE = 101;
    // Photos from 50-200 MP cameras are downsampled to at most this many pixels on the longest side,
    // which keeps the decoded bitmap well within the heap while leaving codes readable.
    private static final int MAX_DECODE_DIMENSION = 4096;

    private Activity activity;
    private ActivityPluginBinding activityBinding;
    private MethodChannel channel;
    private Result pendingResult;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), "qr_scan");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (channel != null) {
            channel.setMethodCallHandler(null);
            channel = null;
        }
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activityBinding = binding;
        activity = binding.getActivity();
        binding.addActivityResultListener(this);
    }

    @Override
    public void onDetachedFromActivity() {
        releaseActivity();
        if (pendingResult != null) {
            pendingResult.error("ACTIVITY_DETACHED", "Activity detached while waiting for result.", null);
            pendingResult = null;
        }
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        // The activity is recreated right away, so keep any pending scan alive.
        releaseActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }

    private void releaseActivity() {
        if (activityBinding != null) {
            activityBinding.removeActivityResultListener(this);
            activityBinding = null;
        }
        activity = null;
    }

    @Override
    public void onMethodCall(MethodCall call, @NonNull Result result) {
        if (activity == null) {
            result.error("NO_ACTIVITY", "Plugin is not attached to an activity.", null);
            return;
        }

        switch (call.method) {
            case "scan":
                if (pendingResult != null) {
                    result.error("BUSY", "A scan is already in progress.", null);
                    return;
                }
                pendingResult = result;
                startCameraScan();
                break;
            case "scan_photo":
                if (pendingResult != null) {
                    result.error("BUSY", "A scan is already in progress.", null);
                    return;
                }
                pendingResult = result;
                choosePhoto();
                break;
            case "scan_path": {
                String path = call.argument("path");
                if (path == null || path.trim().isEmpty()) {
                    result.error("INVALID_PATH", "Image path is empty.", null);
                    return;
                }
                Bitmap bitmap = decodeFile(path);
                if (bitmap == null) {
                    result.error("IMAGE_LOAD_FAILED", "Unable to decode image from path.", null);
                    return;
                }
                result.success(decodeBitmap(bitmap));
                break;
            }
            case "scan_bytes": {
                byte[] bytes = call.argument("bytes");
                Bitmap bitmap = decodeBytes(bytes);
                if (bitmap == null) {
                    result.error("INVALID_IMAGE_BYTES", "Unable to decode image bytes.", null);
                    return;
                }
                result.success(decodeBitmap(bitmap));
                break;
            }
            case "generate_barcode":
                generateQrCode(call, result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void startCameraScan() {
        IntentIntegrator integrator = new IntentIntegrator(activity);
        integrator.setDesiredBarcodeFormats(IntentIntegrator.ALL_CODE_TYPES);
        integrator.setOrientationLocked(false);
        integrator.setPrompt("Scan a barcode or QR code");
        integrator.initiateScan();
    }

    private void choosePhoto() {
        // Android 13+ ships the system photo picker, which needs no storage or media permission.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            try {
                activity.startActivityForResult(new Intent(MediaStore.ACTION_PICK_IMAGES).setType("image/*"), REQUEST_IMAGE);
                return;
            } catch (ActivityNotFoundException e) {
                Log.w(TAG, "System photo picker unavailable, falling back to ACTION_PICK", e);
            }
        }

        try {
            activity.startActivityForResult(new Intent(Intent.ACTION_PICK).setType("image/*"), REQUEST_IMAGE);
        } catch (ActivityNotFoundException e) {
            pendingResult.error("NO_IMAGE_PICKER", "No activity available to pick an image.", null);
            pendingResult = null;
        }
    }

    private void generateQrCode(MethodCall call, Result result) {
        String code = call.argument("code");
        if (code == null || code.isEmpty()) {
            result.error("INVALID_CODE", "Code must not be empty.", null);
            return;
        }

        try {
            Map<EncodeHintType, Object> hints = new HashMap<>();
            hints.put(EncodeHintType.CHARACTER_SET, StandardCharsets.UTF_8.name());

            BitMatrix matrix = new MultiFormatWriter().encode(code, com.google.zxing.BarcodeFormat.QR_CODE, 400, 400, hints);
            int width = matrix.getWidth();
            int height = matrix.getHeight();
            int[] pixels = new int[width * height];

            for (int y = 0; y < height; y++) {
                for (int x = 0; x < width; x++) {
                    pixels[y * width + x] = matrix.get(x, y) ? 0xFF000000 : 0xFFFFFFFF;
                }
            }

            Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
            bitmap.setPixels(pixels, 0, width, 0, 0, width, height);
            ByteArrayOutputStream output = new ByteArrayOutputStream();
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, output);
            result.success(output.toByteArray());
        } catch (Exception e) {
            result.error("GENERATE_FAILED", e.getMessage(), null);
        }
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        IntentResult cameraResult = IntentIntegrator.parseActivityResult(requestCode, resultCode, data);
        if (cameraResult != null) {
            if (pendingResult != null) {
                pendingResult.success(cameraResult.getContents());
                pendingResult = null;
            }
            return true;
        }

        if (requestCode == REQUEST_IMAGE) {
            if (pendingResult == null) {
                return true;
            }

            if (resultCode != Activity.RESULT_OK || data == null || data.getData() == null) {
                pendingResult.success(null);
                pendingResult = null;
                return true;
            }

            Uri uri = data.getData();
            try {
                Bitmap bitmap = decodeUri(uri);
                if (bitmap == null) {
                    pendingResult.error("IMAGE_LOAD_FAILED", "Unable to load selected image.", null);
                } else {
                    pendingResult.success(decodeBitmap(bitmap));
                }
            } catch (Exception e) {
                Log.e(TAG, "Photo scan failed", e);
                pendingResult.error("SCAN_FAILED", e.getMessage(), null);
            } finally {
                pendingResult = null;
            }
            return true;
        }

        return false;
    }

    private static Bitmap decodeFile(String path) {
        BitmapFactory.Options bounds = boundsOnlyOptions();
        BitmapFactory.decodeFile(path, bounds);
        return BitmapFactory.decodeFile(path, sampledOptions(bounds));
    }

    private static Bitmap decodeBytes(byte[] bytes) {
        if (bytes == null || bytes.length == 0) {
            return null;
        }
        BitmapFactory.Options bounds = boundsOnlyOptions();
        BitmapFactory.decodeByteArray(bytes, 0, bytes.length, bounds);
        return BitmapFactory.decodeByteArray(bytes, 0, bytes.length, sampledOptions(bounds));
    }

    private Bitmap decodeUri(Uri uri) throws IOException {
        BitmapFactory.Options bounds = boundsOnlyOptions();
        try (InputStream input = activity.getContentResolver().openInputStream(uri)) {
            if (input == null) {
                return null;
            }
            BitmapFactory.decodeStream(input, null, bounds);
        }
        try (InputStream input = activity.getContentResolver().openInputStream(uri)) {
            if (input == null) {
                return null;
            }
            return BitmapFactory.decodeStream(input, null, sampledOptions(bounds));
        }
    }

    private static BitmapFactory.Options boundsOnlyOptions() {
        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inJustDecodeBounds = true;
        return options;
    }

    private static BitmapFactory.Options sampledOptions(BitmapFactory.Options bounds) {
        int longestSide = Math.max(bounds.outWidth, bounds.outHeight);
        int sampleSize = 1;
        while (longestSide / sampleSize > MAX_DECODE_DIMENSION) {
            sampleSize *= 2;
        }
        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inSampleSize = sampleSize;
        return options;
    }

    private String decodeBitmap(Bitmap bitmap) {
        int width = bitmap.getWidth();
        int height = bitmap.getHeight();
        int[] pixels = new int[width * height];
        bitmap.getPixels(pixels, 0, width, 0, 0, width, height);

        RGBLuminanceSource source = new RGBLuminanceSource(width, height, pixels);
        BinaryBitmap binaryBitmap = new BinaryBitmap(new HybridBinarizer(source));

        try {
            com.google.zxing.Result decoded = new MultiFormatReader().decode(binaryBitmap);
            return decoded.getText();
        } catch (NotFoundException e) {
            return null;
        }
    }
}
