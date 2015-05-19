Pod::Spec.new do |s|
  s.name         = "LewReorderableLayout"
  s.version      = "0.1.0"
  s.summary      = "A UICollectionView layout which you can move items with drag and drop."
  s.homepage     = "https://github.com/pljhonglu/LewReorderableLayout"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "pljhonglu" => "pljhonglu@gmail.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/pljhonglu/LewReorderableLayout.git", :tag => "v0.1.0" }
  s.source_files = "LewReorderableLayout/*.{h,m}"
  s.requires_arc = true
end