// 生成 Better Things 应用图标（1024×1024 PNG）
// 用法: swift scripts/make-icon.swift <输出路径>
import AppKit

guard CommandLine.arguments.count > 1 else {
    FileHandle.standardError.write("usage: make-icon.swift <output.png>\n".data(using: .utf8)!)
    exit(1)
}
let output = CommandLine.arguments[1]

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

// 背景：圆角矩形 + 蓝色渐变
let rect = NSRect(x: 64, y: 64, width: 896, height: 896)
let background = NSBezierPath(roundedRect: rect, xRadius: 180, yRadius: 180)
background.addClip()
NSGradient(colors: [
    NSColor(red: 0.28, green: 0.58, blue: 1.00, alpha: 1),
    NSColor(red: 0.10, green: 0.28, blue: 0.85, alpha: 1)
])?.draw(in: rect, angle: -90)

// 白色对勾
let check = NSBezierPath()
check.lineWidth = 96
check.lineCapStyle = .round
check.lineJoinStyle = .round
check.move(to: NSPoint(x: 290, y: 530))
check.curve(
    to: NSPoint(x: 450, y: 375),
    controlPoint1: NSPoint(x: 375, y: 510),
    controlPoint2: NSPoint(x: 415, y: 440)
)
check.line(to: NSPoint(x: 735, y: 665))
NSColor.white.setStroke()
check.stroke()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("render failed\n".data(using: .utf8)!)
    exit(1)
}
try! png.write(to: URL(fileURLWithPath: output))
print("icon written: \(output)")
