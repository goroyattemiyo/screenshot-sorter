package com.goroyattemiyo.screenshot_sorter

import android.content.Intent
import android.media.MediaScannerConnection
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.goroyattemiyo.screenshot_sorter/media_scanner"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanFile" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        MediaScannerConnection.scanFile(this, arrayOf(path), null) { _, uri ->
                            result.success(uri?.toString())
                        }
                    } else {
                        result.error("INVALID_PATH", "Path is null", null)
                    }
                }
                "openGallery" -> {
                    try {
                        // Try the standard gallery intent first
                        val intent = Intent(Intent.ACTION_MAIN)
                        intent.addCategory(Intent.CATEGORY_APP_GALLERY)
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(true)
                    } catch (e1: Exception) {
                        try {
                            // Fallback: open image viewer
                            val intent = Intent(Intent.ACTION_VIEW)
                            intent.type = "image/*"
                            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            startActivity(intent)
                            result.success(true)
                        } catch (e2: Exception) {
                            try {
                                // Fallback 2: open MIUI gallery directly
                                val intent = Intent()
                                intent.setClassName("com.miui.gallery", "com.miui.gallery.activity.HomePageActivity")
                                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                startActivity(intent)
                                result.success(true)
                            } catch (e3: Exception) {
                                result.error("NO_GALLERY", "Could not open gallery: " + e3.message, null)
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
