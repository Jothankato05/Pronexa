# iOS side of Pronexa's on-phone food recogniser (local plugin, not published).
Pod::Spec.new do |s|
  s.name             = 'pronexa_lens'
  s.version          = '1.0.0'
  s.summary          = 'Runs the Pronexa food recogniser on iOS with ONNX Runtime.'
  s.homepage         = 'https://github.com/Jothankato05/pronexa'
  s.license          = { :type => 'Proprietary' }
  s.author           = { 'Pronexa' => 'noreply@github.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.swift'
  s.platform         = :ios, '15.1'
  s.swift_version    = '5.0'
  s.static_framework = true
  s.dependency 'Flutter'
  # Same ONNX Runtime version as Android (android/app/build.gradle.kts). Pinned exactly.
  s.dependency 'onnxruntime-objc', '1.28.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
