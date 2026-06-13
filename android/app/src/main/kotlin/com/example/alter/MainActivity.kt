package com.example.alter

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, WAKE_SERVICE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startWakeService" -> {
                    val missingPermissionMessage = requestWakePermissionsIfNeeded()
                    if (missingPermissionMessage != null) {
                        result.error("permissions_required", missingPermissionMessage, null)
                        return@setMethodCallHandler
                    }

                    val intent = Intent(this, HeyAlterWakeService::class.java)
                        .setAction(HeyAlterWakeService.ACTION_START)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(true)
                }

                "stopWakeService" -> {
                    stopService(
                        Intent(this, HeyAlterWakeService::class.java)
                            .setAction(HeyAlterWakeService.ACTION_STOP),
                    )
                    result.success(true)
                }

                "isOnDeviceWakeAvailable" -> {
                    val available = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                        android.speech.SpeechRecognizer.isOnDeviceRecognitionAvailable(this)
                    result.success(available)
                }

                "isSpeechRecognitionAvailable" -> {
                    result.success(android.speech.SpeechRecognizer.isRecognitionAvailable(this))
                }

                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, WAKE_EVENTS_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    HeyAlterWakeEvents.attach(events)
                }

                override fun onCancel(arguments: Any?) {
                    HeyAlterWakeEvents.detach()
                }
            },
        )

        MethodChannel(messenger, DEVICE_CONTROL_CHANNEL).setMethodCallHandler { call, result ->
            DeviceControlBridge.handle(this, call, result)
        }
    }

    private fun requestWakePermissionsIfNeeded(): String? {
        val permissions = mutableListOf<String>()
        if (!hasPermission(Manifest.permission.RECORD_AUDIO)) {
            permissions += Manifest.permission.RECORD_AUDIO
        }
        if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            !hasPermission(Manifest.permission.POST_NOTIFICATIONS)
        ) {
            permissions += Manifest.permission.POST_NOTIFICATIONS
        }

        if (permissions.isEmpty()) return null
        requestPermissions(permissions.toTypedArray(), WAKE_PERMISSION_REQUEST)
        return "Approve microphone permission, then start Hey Alter again."
    }

    private fun hasPermission(permission: String): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
    }

    companion object {
        private const val WAKE_SERVICE_CHANNEL = "alter.ai/wake_service"
        private const val WAKE_EVENTS_CHANNEL = "alter.ai/wake_events"
        private const val DEVICE_CONTROL_CHANNEL = "alter.ai/device_control"
        private const val WAKE_PERMISSION_REQUEST = 9124
    }
}
