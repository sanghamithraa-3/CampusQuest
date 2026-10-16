package edu.tce.campusquest

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "campusquest/storage"
    private val fileName = "campusquest-records.json"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "load" -> {
                        val content = try {
                            openFileInput(fileName).bufferedReader().use { it.readText() }
                        } catch (_: java.io.FileNotFoundException) {
                            null
                        } catch (_: Exception) {
                            null
                        }
                        result.success(content)
                    }
                    "save" -> {
                        val content = call.argument<String>("content")
                        if (content == null) {
                            result.error("INVALID_DATA", "Missing saved content", null)
                        } else {
                            try {
                                openFileOutput(fileName, Context.MODE_PRIVATE).bufferedWriter().use { it.write(content) }
                                result.success(null)
                            } catch (error: Exception) {
                                result.error("SAVE_FAILED", error.message, null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
