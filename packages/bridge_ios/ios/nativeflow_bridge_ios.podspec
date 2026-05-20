Pod::Spec.new do |s|
  s.name = 'nativeflow_bridge_ios'
  s.version = '0.1.0'
  s.summary = 'iOS Swift runtime shell for generated NativeFlow Bridge Flutter plugins.'
  s.description = <<-DESC
iOS Swift runtime shell for generated NativeFlow Bridge Flutter plugins and native bridges.
  DESC
  s.homepage = 'https://github.com/Anu-Code07/flutter-native-bridge'
  s.license = { :type => 'MIT', :file => '../LICENSE' }
  s.author = { 'Anurag' => 'https://github.com/Anu-Code07' }
  s.source = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.swift_version = '5.0'
end
