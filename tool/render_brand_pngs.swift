// Renders a PNG of every logo in assets/brand into assets/brand/png.
//
// Run from the repository root on macOS:
//   swift tool/render_brand_pngs.swift
//
// Each PNG is 2048 px on its long side and keeps the SVG's transparency, so
// the one-colour versions can sit on any background.

import AppKit

let brand = URL(fileURLWithPath: "assets/brand")
let output = brand.appendingPathComponent("png")
let longSide = 2048.0

try! FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

let svgs = try! FileManager.default
  .contentsOfDirectory(at: brand, includingPropertiesForKeys: nil)
  .filter { $0.pathExtension == "svg" }
  .sorted { $0.lastPathComponent < $1.lastPathComponent }

for source in svgs {
  guard let svg = NSImage(contentsOf: source) else {
    fatalError("Cannot load \(source.path)")
  }
  let scale = longSide / max(svg.size.width, svg.size.height)
  let width = Int((svg.size.width * scale).rounded())
  let height = Int((svg.size.height * scale).rounded())

  let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
  rep.size = NSSize(width: width, height: height)
  NSGraphicsContext.saveGraphicsState()
  let context = NSGraphicsContext(bitmapImageRep: rep)!
  context.imageInterpolation = .high
  NSGraphicsContext.current = context
  svg.draw(in: NSRect(x: 0, y: 0, width: width, height: height))
  NSGraphicsContext.restoreGraphicsState()

  let name = source.deletingPathExtension().lastPathComponent + ".png"
  let png = rep.representation(using: .png, properties: [:])!
  try! png.write(to: output.appendingPathComponent(name))
  print("assets/brand/png/\(name) (\(width) × \(height) px)")
}
