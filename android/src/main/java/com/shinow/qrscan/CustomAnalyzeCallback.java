package com.shinow.qrscan;

import android.graphics.Bitmap;
import io.flutter.plugin.common.MethodChannel.Result;
import com.uuzuche.lib_zxing.activity.CodeUtils;

public class CustomAnalyzeCallback implements CodeUtils.AnalyzeCallback {
    private final Result result;
    private final String errorCode;

    public CustomAnalyzeCallback(Result result) {
        this(result, "ANALYZE_FAILED");
    }

    public CustomAnalyzeCallback(Result result, String errorCode) {
        this.result = result;
        this.errorCode = errorCode;
    }

    @Override
    public void onAnalyzeSuccess(Bitmap mBitmap, String result) {
        this.result.success(result);
    }

    @Override
    public void onAnalyzeFailed() {
        this.result.error(errorCode, "Failed to decode barcode/QR code from image.", null);
    }
}
