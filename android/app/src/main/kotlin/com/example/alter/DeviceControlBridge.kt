package com.example.alter

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

object DeviceControlBridge {
    fun handle(activity: Activity, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAccessibilityEnabled" -> result.success(AlterAccessibilityService.isEnabled())
            "openAccessibilitySettings" -> result.success(
                openSettingsIntent(activity, Settings.ACTION_ACCESSIBILITY_SETTINGS),
            )
            "openApp" -> result.success(openApp(activity, call))
            "openSettings" -> result.success(openSettings(activity, call.stringArg("screen")))
            "openDialer" -> result.success(openDialer(activity, call.stringArg("number")))
            "openSmsDraft" -> result.success(
                openSmsDraft(
                    activity,
                    call.stringArg("number"),
                    call.stringArg("text"),
                ),
            )
            "executeAccessibilityAction" -> result.success(executeAccessibilityAction(call))
            "readScreen" -> result.success(AlterAccessibilityService.readScreen())
            else -> result.notImplemented()
        }
    }

    private fun executeAccessibilityAction(call: MethodCall): Map<String, Any?> {
        if (!AlterAccessibilityService.isEnabled()) {
            return failure("Accessibility is not enabled. Open Android Accessibility settings first.")
        }

        val action = call.stringArg("action")
        val ok = when (action) {
            "back", "home", "recents", "notifications", "quick_settings" ->
                AlterAccessibilityService.globalAction(action)
            "tap" -> AlterAccessibilityService.tap(call.floatArg("x"), call.floatArg("y"))
            "swipe" -> AlterAccessibilityService.swipe(
                call.floatArg("startX"),
                call.floatArg("startY"),
                call.floatArg("endX"),
                call.floatArg("endY"),
                call.longArg("durationMs", 420L),
            )
            "click_text" -> AlterAccessibilityService.clickText(call.stringArg("text"))
            "type_text" -> AlterAccessibilityService.typeText(call.stringArg("text"))
            "scroll" -> AlterAccessibilityService.scroll(call.stringArg("direction"))
            else -> false
        }

        return if (ok) success("Executed accessibility action: $action")
        else failure("Could not execute accessibility action: $action")
    }

    private fun openApp(activity: Activity, call: MethodCall): Map<String, Any?> {
        val packageName = call.stringArg("packageName").ifEmpty {
            packageForAppName(call.stringArg("appName"))
        }
        if (packageName.isEmpty()) {
            return failure("Give ALTER an app name it knows or an Android package name.")
        }

        val launch = activity.packageManager.getLaunchIntentForPackage(packageName)
            ?: return failure("Could not find app package: $packageName")
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            activity.startActivity(launch)
            success("Opened $packageName.")
        } catch (error: Throwable) {
            failure("Could not open $packageName: ${error.message}")
        }
    }

    private fun openSettings(activity: Activity, screen: String): Map<String, Any?> {
        val action = when (screen.lowercase()) {
            "accessibility" -> Settings.ACTION_ACCESSIBILITY_SETTINGS
            "wifi" -> Settings.ACTION_WIFI_SETTINGS
            "bluetooth" -> Settings.ACTION_BLUETOOTH_SETTINGS
            "notification", "notifications" -> Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS
            "app", "apps" -> Settings.ACTION_APPLICATION_SETTINGS
            "battery" -> Settings.ACTION_BATTERY_SAVER_SETTINGS
            "privacy" -> Settings.ACTION_PRIVACY_SETTINGS
            else -> Settings.ACTION_SETTINGS
        }
        return openSettingsIntent(activity, action)
    }

    private fun openSettingsIntent(activity: Activity, action: String): Map<String, Any?> {
        return try {
            activity.startActivity(Intent(action).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            success("Opened Android settings.")
        } catch (error: Throwable) {
            failure("Could not open settings: ${error.message}")
        }
    }

    private fun openDialer(activity: Activity, number: String): Map<String, Any?> {
        val clean = number.replace(Regex("[^\\d+]"), "")
        return try {
            activity.startActivity(
                Intent(Intent.ACTION_DIAL, Uri.parse("tel:$clean"))
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            success("Opened dialer for $clean.")
        } catch (error: Throwable) {
            failure("Could not open dialer: ${error.message}")
        }
    }

    private fun openSmsDraft(
        activity: Activity,
        number: String,
        text: String,
    ): Map<String, Any?> {
        val clean = number.replace(Regex("[^\\d+]"), "")
        return try {
            val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:$clean"))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                .putExtra("sms_body", text)
            activity.startActivity(intent)
            success("Opened SMS draft for $clean.")
        } catch (error: Throwable) {
            failure("Could not open SMS draft: ${error.message}")
        }
    }

    private fun packageForAppName(appName: String): String {
        val key = appName.lowercase().replace(Regex("[^a-z0-9]"), "")
        return commonPackages[key].orEmpty()
    }

    private fun MethodCall.stringArg(name: String): String {
        return (argument<String>(name) ?: "").trim()
    }

    private fun MethodCall.floatArg(name: String): Float {
        val value = argument<Any>(name)
        return (value as? Number)?.toFloat() ?: 0f
    }

    private fun MethodCall.longArg(name: String, fallback: Long): Long {
        val value = argument<Any>(name)
        return (value as? Number)?.toLong() ?: fallback
    }

    private fun success(message: String): Map<String, Any?> {
        return mapOf("ok" to true, "message" to message)
    }

    private fun failure(message: String): Map<String, Any?> {
        return mapOf("ok" to false, "message" to message)
    }

    private val commonPackages = mapOf(
        "whatsapp" to "com.whatsapp",
        "whatsappbusiness" to "com.whatsapp.w4b",
        "messages" to "com.google.android.apps.messaging",
        "sms" to "com.google.android.apps.messaging",
        "gmail" to "com.google.android.gm",
        "chrome" to "com.android.chrome",
        "youtube" to "com.google.android.youtube",
        "instagram" to "com.instagram.android",
        "facebook" to "com.facebook.katana",
        "messenger" to "com.facebook.orca",
        "telegram" to "org.telegram.messenger",
        "linkedin" to "com.linkedin.android",
        "x" to "com.twitter.android",
        "twitter" to "com.twitter.android",
        "maps" to "com.google.android.apps.maps",
        "calendar" to "com.google.android.calendar",
        "photos" to "com.google.android.apps.photos",
        "settings" to "com.android.settings",
    )
}
