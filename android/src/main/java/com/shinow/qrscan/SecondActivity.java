package com.shinow.qrscan;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.hardware.Sensor;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.Toast;

import androidx.activity.OnBackPressedCallback;
import androidx.activity.result.ActivityResult;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AppCompatActivity;

import com.uuzuche.lib_zxing.activity.CaptureFragment;
import com.uuzuche.lib_zxing.activity.CodeUtils;

public class SecondActivity extends AppCompatActivity {

    public static boolean isLightOpen = false;
    private LinearLayout lightLayout;
    private LinearLayout backLayout;
    private LinearLayout photoLayout;
    private SensorManager sensorManager;
    private Sensor lightSensor;
    private SensorEventListener sensorEventListener;
    private final ActivityResultLauncher<Intent> pickImageLauncher =
            registerForActivityResult(new ActivityResultContracts.StartActivityForResult(), this::handlePickImageResult);
    private final OnBackPressedCallback onBackPressedCallback = new OnBackPressedCallback(true) {
        @Override
        public void handleOnBackPressed() {
            finishWithFailedResult();
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_second);
        CaptureFragment captureFragment = new CaptureFragment();
        CodeUtils.setFragmentArgs(captureFragment, R.layout.my_camera);
        captureFragment.setAnalyzeCallback(analyzeCallback);
        getSupportFragmentManager().beginTransaction().replace(R.id.fl_my_container, captureFragment).commit();

        lightLayout = findViewById(R.id.scan_light);
        backLayout = findViewById(R.id.scan_back);
        photoLayout = findViewById(R.id.choose_photo);

        sensorManager = (SensorManager) getSystemService(Context.SENSOR_SERVICE);
        lightSensor = sensorManager.getDefaultSensor(Sensor.TYPE_LIGHT);
        sensorEventListener = new LightSensorEventListener(lightLayout);
        getOnBackPressedDispatcher().addCallback(this, onBackPressedCallback);

        initView();
    }

    @Override
    protected void onResume() {
        // System.out.println("---------------------|||||||||||||---onResume---|||||||||||-------------------------");
        super.onResume();
        if (lightSensor != null) {
            sensorManager.registerListener(sensorEventListener, lightSensor, SensorManager.SENSOR_DELAY_NORMAL);
        }
    }

    @Override
    protected void onPause() {
        // System.out.println("---------------------|||||||||||||---onPause---|||||||||||-------------------------");
        sensorManager.unregisterListener(sensorEventListener);
        super.onPause();
    }

    private void initView() {
        lightLayout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (!isLightOpen) {
                    try {
                        CodeUtils.isLightEnable(true);
                        isLightOpen = true;
                    } catch (Exception e) {
                        Toast.makeText(getApplicationContext(), "Can't use light", Toast.LENGTH_SHORT).show();
                    }
                } else {
                    try {
                        CodeUtils.isLightEnable(false);
                        isLightOpen = false;
                    } catch (Exception e) {
                        Toast.makeText(getApplicationContext(), "Can't use light", Toast.LENGTH_SHORT).show();
                    }
                }
            }
        });
        backLayout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                SecondActivity.this.finish();
            }
        });
        photoLayout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent();
                intent.setAction(Intent.ACTION_PICK);
                intent.setType("image/*");
                pickImageLauncher.launch(intent);
            }
        });
    }

    private void handlePickImageResult(ActivityResult activityResult) {
        if (activityResult.getResultCode() == Activity.RESULT_OK && activityResult.getData() != null) {
            Uri uri = activityResult.getData().getData();
            String path = ImageUtil.getImageAbsolutePath(SecondActivity.this, uri);
            Intent intent = new Intent();
            Bundle bundle = new Bundle();
            bundle.putString("path", path);
            bundle.putString("uri", uri != null ? uri.toString() : null);
            intent.putExtra("secondBundle", bundle);
            setResult(Activity.RESULT_OK, intent);
            SecondActivity.this.finish();
        }
    }

    private void finishWithFailedResult() {
        Intent resultIntent = new Intent();
        Bundle bundle = new Bundle();
        bundle.putInt(CodeUtils.RESULT_TYPE, CodeUtils.RESULT_FAILED);
        resultIntent.putExtras(bundle);
        SecondActivity.this.setResult(RESULT_OK, resultIntent);
        SecondActivity.this.finish();
    }

    private CodeUtils.AnalyzeCallback analyzeCallback = new CodeUtils.AnalyzeCallback() {
        @Override
        public void onAnalyzeSuccess(Bitmap mBitmap, String result) {
            Intent resultIntent = new Intent();
            Bundle bundle = new Bundle();
            bundle.putInt(CodeUtils.RESULT_TYPE, CodeUtils.RESULT_SUCCESS);
            bundle.putString(CodeUtils.RESULT_STRING, result);
            resultIntent.putExtras(bundle);
            SecondActivity.this.setResult(RESULT_OK, resultIntent);
            SecondActivity.this.finish();
        }

        @Override
        public void onAnalyzeFailed() {
            Intent resultIntent = new Intent();
            Bundle bundle = new Bundle();
            bundle.putInt(CodeUtils.RESULT_TYPE, CodeUtils.RESULT_FAILED);
            bundle.putString(CodeUtils.RESULT_STRING, "");
            resultIntent.putExtras(bundle);
            SecondActivity.this.setResult(RESULT_OK, resultIntent);
            SecondActivity.this.finish();
        }
    };

}
