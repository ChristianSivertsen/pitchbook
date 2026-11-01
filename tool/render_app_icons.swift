// Renders the launcher icons from assets/brand/sva-app-icon.svg.
//
// Run from the repository root on macOS:
//   swift tool/render_app_icons.swift
//
// iOS gets every AppIcon size, Android the legacy ic_launcher.png at every
// density. All files are opaque RGB: the App Store rejects an alpha channel on
// the 1024 icon. The Android adaptive icon is a vector drawable and needs no
// rendering.

import AppKit

let source = URL(fileURLWithPath: "assets/brand/sva-app-icon.svg")
guard let svg = NSImage(contentsOf: source) else {
  fatalError("Cannot load \(source.path)")
}

func render(_ pixels: Int, to path: String) {
  // Draw into an RGBA bitmap first: drawing straight into a 3-sample RGB rep
  // gives a black image.
  let rgba = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
  rgba.size = NSSize(width: pixels, height: pixels)
  NSGraphicsContext.saveGraphicsState()
  let context = NSGraphicsContext(bitmapImageRep: rgba)!
  context.imageInterpolation = .high
  NSGraphicsContext.current = context
  svg.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
  NSGraphicsContext.restoreGraphicsState()

  // Flatten to opaque RGB.
  let rgb = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
    bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
  for y in 0..<pixels {
    for x in 0..<pixels {
      var p = [Int](repeating: 0, count: 4)
      rgba.getPixel(&p, atX: x, y: y)
      var q = [p[0], p[1], p[2]]
      rgb.setPixel(&q, atX: x, y: y)
    }
  }
  let png = rgb.representation(using: .png, properties: [:])!
  try! png.write(to: URL(fileURLWithPath: path))
  print("\(path) (\(pixels) px)")
}

let ios = "app/ios/Runner/Assets.xcassets/AppIcon.appiconset"
let iosSizes: [(points: Double, scales: [Int])] = [
  (20, [1, 2, 3]), (29, [1, 2, 3]), (40, [1, 2, 3]), (60, [2, 3]),
  (76, [1, 2]), (83.5, [2]), (1024, [1]),
]
for (points, scales) in iosSizes {
  let name = points == points.rounded() ? String(Int(points)) : String(points)
  for scale in scales {
    render(Int(points * Double(scale)), to: "\(ios)/Icon-App-\(name)x\(name)@\(scale)x.png")
  }
}

let android = "app/android/app/src/main/res"
let androidSizes = ["mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192]
for (density, pixels) in androidSizes.sorted(by: { $0.value < $1.value }) {
  render(pixels, to: "\(android)/mipmap-\(density)/ic_launcher.png")
}
