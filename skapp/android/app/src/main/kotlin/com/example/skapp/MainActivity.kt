package com.example.skapp  // Replace with your actual package name

import android.os.Build
import android.view.Display
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "high_refresh_rate"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Force high refresh rate immediately
        setHighRefreshRate()
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setHighRefreshRate" -> {
                    setHighRefreshRate()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setHighRefreshRate() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+ approach
            val display = display
            val supportedModes = display?.supportedModes
            var maxRefreshRate = 60f
            
            supportedModes?.forEach { mode ->
                if (mode.refreshRate > maxRefreshRate) {
                    maxRefreshRate = mode.refreshRate
                }
            }
            
            window.attributes = window.attributes.apply {
                preferredRefreshRate = maxRefreshRate
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Android 6+ approach
            window.attributes = window.attributes.apply {
                preferredRefreshRate = 120f // Set your device's max refresh rate
            }
        }
    }
}