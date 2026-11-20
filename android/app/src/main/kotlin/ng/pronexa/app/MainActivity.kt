package ng.pronexa.app

import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val main = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pronexa/lens").setMethodCallHandler { call, result ->
            when (call.method) {
                "recognise" -> {
                    val image = call.argument<FloatArray>("image")
                    if (image == null) {
                        result.error("BAD_INPUT", "No image", null)
                        return@setMethodCallHandler
                    }
                    // Never on the main thread: loading and running the model take seconds.
                    lensThread.execute {
                        try {
                            val out = engine().run(image)
                            main.post { result.success(mapOf("scores" to out[0], "features" to out[1])) }
                        } catch (t: Throwable) {
                            // Includes OutOfMemoryError: report it and let the student pick by hand.
                            closeEngine()
                            main.post { result.error("LENS_FAILED", t.javaClass.simpleName + ": " + t.message, null) }
                        }
                    }
                }
                "prepare" -> {
                    // Load the model in the background while the student takes the photo.
                    lensThread.execute {
                        try {
                            engine().load()
                        } catch (_: Throwable) {
                            closeEngine()
                        }
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    /** The bundled model, copied once to app storage in small chunks (never held in memory whole). */
    private fun modelFile(): File {
        val target = File(filesDir, "lens/pronexa-food-v1.onnx")
        val installed = packageManager.getPackageInfo(packageName, 0).lastUpdateTime
        if (target.exists() && target.length() > 0 && target.lastModified() >= installed) return target
        target.parentFile?.mkdirs()
        val key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset("assets/models/pronexa-food-v1.onnx")
        val tmp = File(target.path + ".tmp")
        assets.open(key).use { input -> tmp.outputStream().use { output -> input.copyTo(output, 1 shl 16) } }
        if (!tmp.renameTo(target)) throw IllegalStateException("Could not store the recogniser")
        return target
    }

    private fun engine(): LensEngine = lens ?: LensEngine(modelFile().path).also { lens = it }

    private fun closeEngine() {
        try {
            lens?.close()
        } catch (_: Throwable) {
        }
        lens = null
    }

    override fun onDestroy() {
        lensThread.execute { closeEngine() }
        super.onDestroy()
    }

    companion object {
        // One background thread shared by every activity instance: requests queue in order.
        private val lensThread: ExecutorService = Executors.newSingleThreadExecutor()

        @Volatile
        private var lens: LensEngine? = null
    }
}
