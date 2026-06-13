package com.example.alter

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.os.Build
import android.util.Base64
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

object NativeAudioBridge {
    private var recorder: MediaRecorder? = null
    private var recordingFile: File? = null
    private var recordingStartedAt: Long = 0L
    private var player: MediaPlayer? = null

    fun handle(activity: Activity, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startRecording" -> result.success(startRecording(activity))
            "stopRecording" -> result.success(stopRecording())
            "cancelRecording" -> result.success(cancelRecording())
            "playAudioBase64" -> result.success(
                playAudioBase64(
                    activity,
                    call.argument<String>("audioBase64").orEmpty(),
                    call.argument<String>("filename").orEmpty(),
                ),
            )
            "stopPlayback" -> result.success(stopPlayback())
            else -> result.notImplemented()
        }
    }

    private fun startRecording(activity: Activity): Map<String, Any?> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            activity.checkSelfPermission(Manifest.permission.RECORD_AUDIO) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return failure("Microphone permission is not granted.")
        }
        if (recorder != null) {
            return failure("Recording is already active.")
        }

        val file = File(activity.cacheDir, "alter_sarvam_voice.m4a")
        val nextRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(activity)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }

        return try {
            nextRecorder.setAudioSource(MediaRecorder.AudioSource.MIC)
            nextRecorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            nextRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            nextRecorder.setAudioEncodingBitRate(96_000)
            nextRecorder.setAudioSamplingRate(16_000)
            nextRecorder.setOutputFile(file.absolutePath)
            nextRecorder.prepare()
            nextRecorder.start()
            recorder = nextRecorder
            recordingFile = file
            recordingStartedAt = System.currentTimeMillis()
            success("Recording started.")
        } catch (error: Throwable) {
            try {
                nextRecorder.release()
            } catch (_: Throwable) {
            }
            recorder = null
            recordingFile = null
            failure("Could not start recording: ${error.message}")
        }
    }

    private fun stopRecording(): Map<String, Any?> {
        val active = recorder ?: return failure("No recording is active.")
        val file = recordingFile ?: return failure("Recording file was not created.")
        return try {
            active.stop()
            active.release()
            recorder = null
            recordingFile = null
            val bytes = file.readBytes()
            mapOf(
                "ok" to true,
                "message" to "Recording captured.",
                "audioBase64" to Base64.encodeToString(bytes, Base64.NO_WRAP),
                "filename" to file.name,
                "contentType" to "audio/mp4",
                "durationMs" to (System.currentTimeMillis() - recordingStartedAt),
            )
        } catch (error: Throwable) {
            try {
                active.release()
            } catch (_: Throwable) {
            }
            recorder = null
            recordingFile = null
            failure("Could not stop recording: ${error.message}")
        }
    }

    private fun cancelRecording(): Map<String, Any?> {
        return try {
            recorder?.stop()
            recorder?.release()
            recordingFile?.delete()
            recorder = null
            recordingFile = null
            success("Recording cancelled.")
        } catch (error: Throwable) {
            recorder = null
            recordingFile = null
            failure("Could not cancel recording: ${error.message}")
        }
    }

    private fun playAudioBase64(
        activity: Activity,
        audioBase64: String,
        filename: String,
    ): Map<String, Any?> {
        if (audioBase64.isBlank()) {
            return failure("No audio was returned.")
        }
        stopPlayback()
        val extension = filename.substringAfterLast('.', "wav").ifBlank { "wav" }
        val file = File(activity.cacheDir, "alter_tts.$extension")
        return try {
            file.writeBytes(Base64.decode(audioBase64, Base64.DEFAULT))
            player = MediaPlayer().apply {
                setDataSource(file.absolutePath)
                setOnCompletionListener {
                    it.release()
                    if (player == it) player = null
                }
                prepare()
                start()
            }
            success("Playing generated voice.")
        } catch (error: Throwable) {
            failure("Could not play generated voice: ${error.message}")
        }
    }

    private fun stopPlayback(): Map<String, Any?> {
        return try {
            player?.stop()
            player?.release()
            player = null
            success("Audio playback stopped.")
        } catch (error: Throwable) {
            player = null
            failure("Could not stop playback: ${error.message}")
        }
    }

    private fun success(message: String): Map<String, Any?> {
        return mapOf("ok" to true, "message" to message)
    }

    private fun failure(message: String): Map<String, Any?> {
        return mapOf("ok" to false, "message" to message)
    }
}
