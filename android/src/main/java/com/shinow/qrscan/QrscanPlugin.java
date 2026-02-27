package com.shinow.qrscan;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;

import androidx.annotation.NonNull;

import com.uuzuche.lib_zxing.activity.CodeUtils;
import com.uuzuche.lib_zxing.activity.ZXingLibrary;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

import static com.uuzuche.lib_zxing.activity.CodeUtils.RESULT_SUCCESS;
import static com.uuzuche.lib_zxing.activity.CodeUtils.RESULT_TYPE;

public class QrscanPlugin implements FlutterPlugin, ActivityAware, MethodCallHandler, PluginRegistry.ActivityResultListener {

    private final static String TAG = "QrscanPlugin";

    private Result result = null;
    private Activity activity;
    private final int REQUEST_CODE = 100;
    private final int REQUEST_IMAGE = 101;

    private MethodChannel channel;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        Log.i(TAG, "onAttachedToEngine: ");
        channel = new MethodChannel(binding.getBinaryMessenger(), "qr_scan");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        channel = null;
        Log.i(TAG, "onDetachedFromEngine: ");
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        Log.i(TAG, "onAttachedToActivity: ");
        activity = binding.getActivity();
        binding.addActivityResultListener(this);
        ZXingLibrary.initDisplayOpinion(activity);
    }

    @Override
    public void onDetachedFromActivity() {
        activity = null;
        Log.i(TAG, "onDetachedFromActivity: ");
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity();
        Log.i(TAG, "onDetachedFromActivityForConfigChanges: ");
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        Log.i(TAG, "onReattachedToActivityForConfigChanges: ");
        onAttachedToActivity(binding);
    }

    @Override
    public void onMethodCall(MethodCall call, @NonNull Result result) {
        Log.i(TAG, "onMethodCall: " + call.method);
        if (activity == null) {
            result.error("NO_ACTIVITY", "Plugin is not attached to an activity.", null);
            return;
        }
        switch (call.method) {
            case "scan":
                Log.i(TAG, "scan");
                this.result = result;
                showBarcodeView();
                break;
            case "scan_photo":
                this.result = result;
                choosePhotos();
                break;
            case "scan_path":
                this.result = result;
                String path = call.argument("path");
                if (path == null || path.isEmpty()) {
                    this.result.error("INVALID_PATH", "Image path is empty.", null);
                } else {
                    CodeUtils.AnalyzeCallback analyzeCallback = new CustomAnalyzeCallback(this.result);
                    CodeUtils.analyzeBitmap(path, analyzeCallback);
                }
                break;
            case "scan_bytes":
                this.result = result;
                byte[] bytes = call.argument("bytes");
                Bitmap bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes != null ? bytes.length : 0);
                if (bitmap == null) {
                    this.result.error("INVALID_IMAGE_BYTES", "Unable to decode image bytes.", null);
                } else {
                    CodeUtils.analyzeBitmap(bitmap, new CustomAnalyzeCallback(this.result));
                }
                break;
            case "generate_barcode":
                this.result = result;
                generateQrCode(call);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void showBarcodeView() {
        Intent intent = new Intent(activity, SecondActivity.class);
        activity.startActivityForResult(intent, REQUEST_CODE);
    }

    private void choosePhotos() {
        Intent intent = new Intent();
        intent.setAction(Intent.ACTION_PICK);
        intent.setType("image/*");
        activity.startActivityForResult(intent, REQUEST_IMAGE);
    }

    private void generateQrCode(MethodCall call) {
        String code = call.argument("code");
        Bitmap bitmap = CodeUtils.createImage(code, 400, 400, null);
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, baos);
        byte[] datas = baos.toByteArray();
        this.result.success(datas);
    }

    @Override
    public boolean onActivityResult(int code, int resultCode, Intent intent) {
        if (code == REQUEST_CODE) {
            if (this.result == null) {
                return true;
            }

            if (resultCode != Activity.RESULT_OK || intent == null) {
                this.result.success(null);
                return true;
            }

            if (resultCode == Activity.RESULT_OK && intent != null) {
                Bundle secondBundle = intent.getBundleExtra("secondBundle");
                if (secondBundle != null) {
                    try {
                        String path = secondBundle.getString("path");
                        String uriValue = secondBundle.getString("uri");
                        Uri uri = uriValue != null ? Uri.parse(uriValue) : null;
                        if (!analyzeBitmapFromPathOrUri(path, uri)) {
                            this.result.error("IMAGE_LOAD_FAILED", "Unable to load selected image.", null);
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                        this.result.error("IMAGE_LOAD_FAILED", e.getMessage(), null);
                    }
                } else {
                    Bundle bundle = intent.getExtras();
                    if (bundle != null) {
                        if (bundle.getInt(RESULT_TYPE) == RESULT_SUCCESS) {
                            String barcode = bundle.getString(CodeUtils.RESULT_STRING);
                            this.result.success(barcode);
                        } else {
                            this.result.success(null);
                        }
                    } else {
                        this.result.success(null);
                    }
                }
            }
            return true;
        } else if (code == REQUEST_IMAGE) {
            if (this.result == null) {
                return true;
            }

            if (resultCode != Activity.RESULT_OK || intent == null) {
                this.result.success(null);
                return true;
            }

            Uri uri = intent.getData();
            if (uri == null) {
                this.result.error("INVALID_IMAGE_URI", "No image URI was returned by the picker.", null);
                return true;
            }

            try {
                String path = ImageUtil.getImageAbsolutePath(activity, uri);
                if (!analyzeBitmapFromPathOrUri(path, uri)) {
                    this.result.error("IMAGE_LOAD_FAILED", "Unable to load selected image.", null);
                }
            } catch (Exception e) {
                e.printStackTrace();
                this.result.error("IMAGE_LOAD_FAILED", e.getMessage(), null);
            }
            return true;
        }
        return false;
    }

    private boolean analyzeBitmapFromPathOrUri(String path, Uri uri) {
        if (path != null && !path.isEmpty()) {
            CodeUtils.analyzeBitmap(path, new CustomAnalyzeCallback(this.result));
            return true;
        }

        if (uri == null) {
            return false;
        }

        try (InputStream inputStream = activity.getContentResolver().openInputStream(uri)) {
            if (inputStream == null) {
                return false;
            }
            Bitmap bitmap = BitmapFactory.decodeStream(inputStream);
            if (bitmap == null) {
                return false;
            }
            CodeUtils.analyzeBitmap(bitmap, new CustomAnalyzeCallback(this.result));
            return true;
        } catch (IOException e) {
            Log.e(TAG, "Failed to read image URI: " + uri, e);
            return false;
        }
    }
}
