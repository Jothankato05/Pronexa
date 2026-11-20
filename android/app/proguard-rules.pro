# ONNX Runtime's native library looks up its Java classes, fields and methods by
# name (JNI). The release shrinker must not rename or remove them, or the app
# crashes as soon as the photo recogniser runs.
-keep class ai.onnxruntime.** { *; }
-keepclasseswithmembernames class * { native <methods>; }
-keep class ng.pronexa.app.LensEngine { *; }
