/*
 Copyright 2017 S
 
 This file is part of C0.
 
 C0 is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 C0 is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with C0.  If not, see <http://www.gnu.org/licenses/>.
 */

import CoreGraphics

struct Color: Codable {
    var hue: Real {
        didSet { rgb = Color.hsvWithHSL(h: hue, s: saturation, l: lightness).rgb }
    }
    var saturation: Real {
        didSet { rgb = Color.hsvWithHSL(h: hue, s: saturation, l: lightness).rgb }
    }
    var lightness: Real {
        didSet { rgb = Color.hsvWithHSL(h: hue, s: saturation, l: lightness).rgb }
    }
    var sl: Point {
        get { return Point(x: saturation, y: lightness) }
        set {
            self.saturation = newValue.x
            self.lightness = newValue.y
        }
    }
    var ls: Point {
        get { return Point(x: lightness, y: saturation) }
        set {
            self.lightness = newValue.x
            self.saturation = newValue.y
        }
    }
    var rgbColorSpace: RGBColorSpace
    private(set) var rgb: RGB
    
    init(hue: Real = 0, saturation: Real = 0, lightness: Real = 0,
         rgbColorSpace: RGBColorSpace = .sRGB) {
        
        self.hue = hue
        self.saturation = saturation
        self.lightness = lightness
        rgb = Color.hsvWithHSL(h: hue, s: saturation, l: lightness).rgb
        self.rgbColorSpace = rgbColorSpace
    }
    init(hue: Real, saturation: Real, lightnessFromMaxSaturation: Real,
         rgbColorSpace: RGBColorSpace = .sRGB) {
        
        let hsv = HSV(h: Color.hsvHue(withHSLHue: hue),
                      s: saturation,
                      v: lightnessFromMaxSaturation)
        self.init(hsv: hsv, rgb: hsv.rgb, rgbColorSpace: rgbColorSpace)
    }
    init(hue: Real, saturation: Real, brightness: Real,
         rgbColorSpace: RGBColorSpace = .sRGB) {
        
        let hsv = HSV(h: hue, s: saturation, v: brightness)
        self.init(hsv: hsv, rgb: hsv.rgb, rgbColorSpace: rgbColorSpace)
    }
    init(red: Real, green: Real, blue: Real,
         rgbColorSpace: RGBColorSpace = .sRGB) {
        
        let rgb = RGB(r: red, g: green, b: blue)
        self.init(hsv: rgb.hsv, rgb: rgb, rgbColorSpace: rgbColorSpace)
    }
    init(rgb: RGB, rgbColorSpace: RGBColorSpace = .sRGB) {
        self.init(hsv: rgb.hsv, rgb: rgb, rgbColorSpace: rgbColorSpace)
    }
    init(white: Real, rgbColorSpace: RGBColorSpace = .sRGB) {
        self.init(hue: 0, saturation: 0, lightness: white, rgbColorSpace: rgbColorSpace)
    }
    init(hsv: HSV, rgb: RGB, rgbColorSpace: RGBColorSpace = .sRGB) {
        (hue, saturation, lightness) = Color.hsl(with: hsv)
        self.rgb = rgb
        self.rgbColorSpace = rgbColorSpace
    }
}
extension Color {
    static let white = Color(hue: 0, saturation: 0, lightness: 1)
    static let gray = Color(hue: 0, saturation: 0, lightness: 0.5)
    static let black = Color(hue: 0, saturation: 0, lightness: 0)
    static let red = Color(red: 1, green: 0, blue: 0)
    static let green = Color(hue: 156.0 / 360, saturation: 1, brightness: 0.69)
    static let orange = Color(hue: 38.0 / 360, saturation: 1, brightness: 0.95)
    
    static let background = Color(white: 0.93)
    static let content = Color(white: 0.1)
    static let selected = Color(red: 0.1, green: 0.7, blue: 1)
    static let surface = Color(hue: 0.75, saturation: 0.75, lightness: 0.75)
    static let subLine = Color(red: 0.4, green: 0.75, blue: 1)
    static let draft = Color(red: 0, green: 0.5, blue: 1)
    static let caution = orange
    static let warning = red
}
extension UU where Value == Color {
    static let surface = UU(.surface, id: .zero)
}
extension Color {
    static func random(rgbColorSpace: RGBColorSpace = .sRGB) -> Color {
        let hue = Real.random(min: 0, max: 1)
        let saturation = Real.random(min: 0.5, max: 1)
        let lightness = Real.random(min: 0.4, max: 0.9)
        return Color(hue: hue, saturation: saturation, lightness: lightness,
                     rgbColorSpace: rgbColorSpace)
    }
    
    private static let split = 1.0.cg / 12.0.cg, slow = 0.45.cg, fast = 1.55.cg
    private static func hsvHue(withHSLHue hslHue: Real) -> Real {
        let a = hslHue - 1 / 12
        let hue = a < 0 ? a + 1 : a
        if hue < split {
            return hue * fast
        } else if hue < split * 2 {
            return (hue - split) * slow + split * fast
        } else if hue < split * 3 {
            return (hue - split * 2) * slow + split * (fast + slow)
        } else if hue < split * 4 {
            return (hue - split * 3) * fast + split * (fast + slow * 2)
        } else if hue < split * 5 {
            return (hue - split * 4) * fast + split * (fast * 2 + slow * 2)
        } else if hue < split * 6 {
            return (hue - split * 5) * slow + split * (fast * 3 + slow * 2)
        } else if hue < split * 7 {
            return (hue - split * 6) * slow + split * (fast * 3 + slow * 3)
        } else if hue < split * 8 {
            return (hue - split * 7) * fast + split * (fast * 3 + slow * 4)
        } else if hue < split * 9 {
            return (hue - split * 8) * fast + split * (fast * 4 + slow * 4)
        } else if hue < split * 10 {
            return (hue - split * 9) * slow + split * (fast * 5 + slow * 4)
        } else if hue < split * 11 {
            return (hue - split * 10) * slow + split * (fast * 5 + slow * 5)
        } else {
            return (hue - split * 11) * fast + split * (fast * 5 + slow * 6)
        }
    }
    private static func hslHue(withHSVHue hsvHue: Real) -> Real {
        let a = hsvHue + 1 / 12
        let hue = a > 1 ? a - 1 : a
        if hue < split * fast {
            return hue / fast
        } else if hue < split * (fast + slow) {
            return (hue - split * fast) / slow + split
        } else if hue < split * (fast + slow * 2) {
            return (hue - split * (fast + slow)) / slow + split * 2
        } else if hue < split * (fast * 2 + slow * 2) {
            return (hue - split * (fast + slow * 2)) / fast + split * 3
        } else if hue < split * (fast * 3 + slow * 2) {
            return (hue - split * (fast * 2 + slow * 2)) / fast + split * 4
        } else if hue < split * (fast * 3 + slow * 3) {
            return (hue - split * (fast * 3 + slow * 2)) / slow + split * 5
        } else if hue < split * (fast * 3 + slow * 4) {
            return (hue - split * (fast * 3 + slow * 3)) / slow + split * 6
        } else if hue < split * (fast * 4 + slow * 4) {
            return (hue - split * (fast * 3 + slow * 4)) / fast + split * 7
        } else if hue < split * (fast * 5 + slow * 4) {
            return (hue - split * (fast * 4 + slow * 4)) / fast + split * 8
        } else if hue < split * (fast * 5 + slow * 5) {
            return (hue - split * (fast * 5 + slow * 4)) / slow + split * 9
        } else if hue < split * (fast * 5 + slow * 6) {
            return (hue - split * (fast * 5 + slow * 5)) / slow + split * 10
        } else {
            return (hue - split * (fast * 5 + slow * 6)) / fast + split * 11
        }
    }
    
    func with(hue: Real) -> Color {
        return Color(hue: hue, saturation: saturation, lightness:  lightness)
    }
    func with(saturation: Real) -> Color {
        return Color(hue: hue, saturation: saturation, lightness: lightness)
    }
    func with(lightness: Real) -> Color {
        return Color(hue: hue, saturation: saturation, lightness: lightness)
    }
    func with(saturation: Real, lightness: Real) -> Color {
        return Color(hue: hue, saturation: saturation, lightness: lightness)
    }
    func with(alpha: Real) -> Color {
        return Color(hue: hue, saturation: saturation, lightness: lightness)
    }
    
    func multiply(white: Real) -> Color {
        return Color.linear(self, Color.white, t: white)
    }
    
    private static func hsl(with hsv: HSV) -> (h: Real, s: Real, l: Real) {
        let h = hslHue(withHSVHue: hsv.h), s = hsv.s, v = hsv.v
        let y = Color.y(withHSLHue: h)
        let n = s * (1 - y) + y
        let nb = n == 0 ? 0 : y * v / n
        if nb < y {
            return (h, s, nb)
        } else {
            let n = 1 - y
            let nb = n == 0 ? 1 : (v - y) / n - s
            return (h, nb == 1 ? 0 : s / (1 - nb), n * nb + y)
        }
    }
    private static func hsvWithHSL(h: Real, s: Real, l: Real) -> HSV {
        let y = Color.y(withHSLHue: h)
        if y < l {
            let by = y == 1 ? 0 : (l - y) / (1 - y)
            return HSV(h: hsvHue(withHSLHue: h),
                       s: -s * by + s,
                       v: (1 - y) * (-s * by + s + by) + y)
        } else {
            let by = y == 0 ? 0 : l / y
            return HSV(h: hsvHue(withHSLHue: h),
                       s: s,
                       v: s * by * (1 - y) + by * y)
        }
    }
    var hsv: HSV {
        return Color.hsvWithHSL(h: hue, s: saturation, l: lightness)
    }
    
    static func y(withHSLHue hue: Real) -> Real {
        return y(withHSVHue: hsvHue(withHSLHue: hue))
    }
    static func y(withHSVHue hue: Real) -> Real {
        let hueRGB = HSV(h: hue, s: 1, v: 1).rgb
        return 0.299 * hueRGB.r + 0.587 * hueRGB.g + 0.114 * hueRGB.b
    }
}
extension Color: Equatable {
    static func ==(lhs: Color, rhs: Color) -> Bool {
        return lhs.hue == rhs.hue
            && lhs.saturation == rhs.saturation
            && lhs.lightness == rhs.lightness
            && lhs.rgbColorSpace == rhs.rgbColorSpace
    }
}
extension Color: Hashable {
    var hashValue: Int {
        return Hash.uniformityHashValue(with: [hue.hashValue,
                                               saturation.hashValue,
                                               lightness.hashValue,
                                               rgbColorSpace.hashValue])
    }
}
extension Color: Interpolatable {
    static func linear(_ f0: Color, _ f1: Color, t: Real) -> Color {
        let rgb = RGB.linear(f0.rgb, f1.rgb, t: t)
        let color = Color(rgb: rgb)
        return color.saturation > 0 ?
            color :
            color.with(hue: Real.linear(f0.hue,
                                        f1.hue.loopValue(other: f0.hue),
                                        t: t).loopValue())
    }
    static func firstMonospline(_ f1: Color, _ f2: Color, _ f3: Color,
                                with ms: Monospline) -> Color {
        let rgb = RGB.firstMonospline(f1.rgb, f2.rgb, f3.rgb, with: ms)
        let color = Color(rgb: rgb)
        return color.saturation > 0 ?
            color :
            color.with(hue: Real.firstMonospline(f1.hue,
                                                 f2.hue.loopValue(other: f1.hue),
                                                 f3.hue.loopValue(other: f1.hue),
                                                 with: ms).loopValue())
    }
    static func monospline(_ f0: Color, _ f1: Color, _ f2: Color, _ f3: Color,
                           with ms: Monospline) -> Color {
        let rgb = RGB.monospline(f0.rgb, f1.rgb, f2.rgb, f3.rgb, with: ms)
        let color = Color(rgb: rgb)
        return color.saturation > 0 ?
            color :
            color.with(hue: Real.monospline(f0.hue,
                                            f1.hue.loopValue(other: f0.hue),
                                            f2.hue.loopValue(other: f0.hue),
                                            f3.hue.loopValue(other: f0.hue),
                                            with: ms).loopValue())
    }
    static func lastMonospline(_ f0: Color, _ f1: Color, _ f2: Color,
                               with ms: Monospline) -> Color {
        let rgb = RGB.lastMonospline(f0.rgb, f1.rgb, f2.rgb, with: ms)
        let color = Color(rgb: rgb)
        return color.saturation > 0 ?
            color :
            color.with(hue: Real.lastMonospline(f0.hue,
                                                f1.hue.loopValue(other: f0.hue),
                                                f2.hue.loopValue(other: f0.hue),
                                                with: ms).loopValue())
    }
}
extension Color: Viewable {
    func viewWith<T: BinderProtocol>
        (binder: T, keyPath: ReferenceWritableKeyPath<T, Color>) -> ModelView {
        
        return ColorView(binder: binder, keyPath: keyPath)
    }
}
extension Color: ObjectViewable {}

struct RGB {
    var r = 0.0.cg, g = 0.0.cg, b = 0.0.cg
}
extension RGB {
    var hsv: HSV {
        let minValue = min(r, g, b), maxValue = max(r, g, b)
        let d = maxValue - minValue
        let s = maxValue == 0 ? d : d / maxValue, v = maxValue
        let h: Real = {
            guard d > 0 else {
                return d / 6
            }
            if r == maxValue {
                let hh = (g - b) / d
                return (hh < 0 ? hh + 6 : hh) / 6
            } else if g == maxValue {
                return (2 + (b - r) / d) / 6
            } else {
                return (4 + (r - g) / d) / 6
            }
        } ()
        return HSV(h: h, s: s, v: v)
    }
}
extension RGB: Codable {
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let r = try container.decode(Real.self)
        let g = try container.decode(Real.self)
        let b = try container.decode(Real.self)
        self.init(r: r, g: g, b: b)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(r)
        try container.encode(g)
        try container.encode(b)
    }
}
extension RGB: Interpolatable {
    static func linear(_ f0: RGB, _ f1: RGB, t: Real) -> RGB {
        let r = Real.linear(f0.r, f1.r, t: t)
        let g = Real.linear(f0.g, f1.g, t: t)
        let b = Real.linear(f0.b, f1.b, t: t)
        return RGB(r: r, g: g, b: b)
    }
    static func firstMonospline(_ f1: RGB, _ f2: RGB, _ f3: RGB,
                                with ms: Monospline) -> RGB {
        let r = Real.firstMonospline(f1.r, f2.r, f3.r, with: ms)
        let g = Real.firstMonospline(f1.g, f2.g, f3.g, with: ms)
        let b = Real.firstMonospline(f1.b, f2.b, f3.b, with: ms)
        return RGB(r: r, g: g, b: b)
    }
    static func monospline(_ f0: RGB, _ f1: RGB, _ f2: RGB, _ f3: RGB,
                           with ms: Monospline) -> RGB {
        let r = Real.monospline(f0.r, f1.r, f2.r, f3.r, with: ms)
        let g = Real.monospline(f0.g, f1.g, f2.g, f3.g, with: ms)
        let b = Real.monospline(f0.b, f1.b, f2.b, f3.b, with: ms)
        return RGB(r: r, g: g, b: b)
    }
    static func lastMonospline(_ f0: RGB, _ f1: RGB, _ f2: RGB,
                               with ms: Monospline) -> RGB {
        let r = Real.lastMonospline(f0.r, f1.r, f2.r, with: ms)
        let g = Real.lastMonospline(f0.g, f1.g, f2.g, with: ms)
        let b = Real.lastMonospline(f0.b, f1.b, f2.b, with: ms)
        return RGB(r: r, g: g, b: b)
    }
}

struct HSV {
    var h = 0.0.cg, s = 0.0.cg, v = 0.0.cg
}
extension HSV {
    var rgb: RGB {
        guard s != 0 else {
            return RGB(r: v, g: v, b: v)
        }
        let h6 = 6 * h
        let hi = Int(h6)
        let nh = h6 - Real(hi)
        switch (hi) {
        case 0: return RGB(r: v, g: v * (1 - s * (1 - nh)), b: v * (1 - s))
        case 1: return RGB(r: v * (1 - s * nh), g: v, b: v * (1 - s))
        case 2: return RGB(r: v * (1 - s), g: v, b: v * (1 - s * (1 - nh)))
        case 3: return RGB(r: v * (1 - s), g: v * (1 - s * nh), b: v)
        case 4: return RGB(r: v * (1 - s * (1 - nh)), g: v * (1 - s), b: v)
        default: return RGB(r: v, g: v * (1 - s), b: v * (1 - s * nh))
        }
    }
}
extension HSV: Codable {
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let h = try container.decode(Real.self)
        let s = try container.decode(Real.self)
        let v = try container.decode(Real.self)
        self.init(h: h, s: s, v: v)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(h)
        try container.encode(s)
        try container.encode(v)
    }
}

enum RGBColorSpace: Int8, Codable, Hashable {
    case sRGB, displayP3
}
extension RGBColorSpace: CustomStringConvertible {
    var description: String {
        switch self {
        case .sRGB: return "sRGB"
        case .displayP3: return "Display P3"
        }
    }
}
extension RGBColorSpace {
    var displayText: Localization {
        return Localization(description)
    }
    static var displayTexts: [Localization] {
        return [sRGB.displayText, displayP3.displayText]
    }
}

extension Color {
    init(_ cgColor: CGColor) {
        guard cgColor.numberOfComponents == 4,
            let components = cgColor.components,
            let name = cgColor.colorSpace?.name as String? else {
                self.init()
                return
        }
        switch name {
        case String(CGColorSpace.sRGB):
            self.init(red: Real(components[0]),
                      green: Real(components[1]),
                      blue: Real(components[2]),
                      rgbColorSpace: .sRGB)
        case String(CGColorSpace.displayP3):
            self.init(red: Real(components[0]),
                      green: Real(components[1]),
                      blue: Real(components[2]),
                      rgbColorSpace: .displayP3)
        default:
            self.init()
        }
    }
    
    func with(colorSpace: RGBColorSpace) -> Color {
        guard
            let cs = CGColorSpace.with(colorSpace),
            let cgColor = self.cg.converted(to: cs, intent: .defaultIntent, options: nil),
            let cps = cgColor.components, cgColor.numberOfComponents == 4 else {
                return self
        }
        return Color(red: Real(cps[0]), green: Real(cps[1]), blue: Real(cps[2]),
                     rgbColorSpace: rgbColorSpace)
    }
    
    var cg: CGColor {
        return CGColor.with(rgb: rgb, alpha: 1, colorSpace: CGColorSpace.with(rgbColorSpace))
    }
}

extension CGColor {
    static func with(rgb: RGB, alpha a: Real = 1, colorSpace: CGColorSpace? = nil) -> CGColor {
        let cs = colorSpace ?? CGColorSpaceCreateDeviceRGB()
        let cps = [Real(rgb.r), Real(rgb.g), Real(rgb.b), Real(a)]
        return CGColor(colorSpace: cs, components: cps)
            ?? CGColor(red: cps[0], green: cps[1], blue: cps[2], alpha: cps[3])
    }
}
extension CGColorSpace {
    static let `default` = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
    static var labColorSpace: CGColorSpace? {
        return CGColorSpace(labWhitePoint: [0.95947, 1, 1.08883],
                            blackPoint: [0, 0, 0],
                            range: [-127, 127, -127, 127])
    }
    static func with(_ colorSpace: RGBColorSpace) -> CGColorSpace? {
        switch colorSpace {
        case .sRGB: return CGColorSpace(name: CGColorSpace.sRGB)
        case .displayP3: return CGColorSpace(name: CGColorSpace.displayP3)
        }
    }
}

struct HueCircle {
    var lineWidth: Real, rgbColorSpace: RGBColorSpace
    var bounds: Rect {
        didSet {
            radius = min(bounds.width, bounds.height) / 2
        }
    }
    private(set) var radius: Real
    
    init(lineWidth: Real = Layouter.padding * 2,
         bounds: Rect = Rect(), rgbColorSpace: RGBColorSpace = .sRGB) {
        
        self.lineWidth = lineWidth
        self.bounds = bounds
        self.radius = min(bounds.width, bounds.height) / 2
        self.rgbColorSpace = rgbColorSpace
    }
    
    func draw(in ctx: CGContext) {
        let outR = radius
        let inR = outR - lineWidth, deltaAngle = 1 / outR
        let splitCount = Int(ceil(2 * .pi * outR))
        let inChord = 2 + inR / outR, outChord = 2.0.cg
        let points = [Point(x: inR, y: inChord / 2), Point(x: outR, y: outChord / 2),
                      Point(x: outR, y: -outChord / 2), Point(x: inR, y: -inChord / 2)]
        ctx.saveGState()
        ctx.translateBy(x: bounds.midX, y: bounds.midY)
        ctx.rotate(by: -(deltaAngle / 2))
        for i in 0..<splitCount {
            let hue = Real(i) / Real(splitCount)
            let color = Color(hue: hue, saturation: 1, lightnessFromMaxSaturation: 1,
                              rgbColorSpace: rgbColorSpace)
            ctx.setFillColor(color.cg)
            ctx.addLines(between: points)
            ctx.fillPath()
            ctx.rotate(by: deltaAngle)
        }
        ctx.restoreGState()
    }
}

final class ColorView<T: BinderProtocol>: ModelView, BindableReceiver {
    typealias Model = Color
    typealias Binder = T
    var binder: Binder {
        didSet { updateWithModel() }
    }
    var keyPath: BinderKeyPath {
        didSet { updateWithModel() }
    }
    var notifications = [((ColorView<Binder>, BasicNotification) -> ())]()
    
    let hueView: CircularRealView<Binder>
    let slView: MovablePointView<Binder>
    
    var hueCircle = HueCircle() {
        didSet { hueDrawView.displayLinkDraw() }
    }
    let hueDrawView = View(drawClosure: { _, _, _ in })
    let slColorGradientView: View
    let slBlackWhiteGradientView: View
    
    init(binder: Binder, keyPath: BinderKeyPath) {
        self.binder = binder
        self.keyPath = keyPath
        
        let valueOption = RealOption(minModel: 0, maxModel: 1)
        let hueWidth = Layouter.movableLineWidth + Layouter.movablePadding * 2
        hueView = CircularRealView(binder: binder, keyPath: keyPath.appending(path: \Color.hue),
                                   option: valueOption, startAngle: 0, width: hueWidth)
        let slOption = PointOption(xOption: valueOption, yOption: valueOption)
        slView = MovablePointView(binder: binder, keyPath: keyPath.appending(path: \Color.ls),
                                   option: slOption)
        
        let hue = binder[keyPath: keyPath].hue
        let y = Color.y(withHSLHue: hue)
        let slc0 = Composition(value: Color(hue: hue, saturation: 0,
                                            lightnessFromMaxSaturation: y))
        let slc1 = Composition(value: Color(hue: hue, saturation: 1,
                                            lightnessFromMaxSaturation: 1))
        let slcValues = [Gradient.Value(colorComposition: slc0, location: 0),
                         Gradient.Value(colorComposition: slc1, location: 1)]
        slColorGradientView = View(gradient: Gradient(values: slcValues,
                                                      startPoint: Point(x: 0, y: 0),
                                                      endPoint: Point(x: 0, y: 1)))
        let slgc0 = Composition(value: Color(white: 0), opacity: 1)
        let slgc1 = Composition(value: Color(white: 0), opacity: 0)
        let slgc2 = Composition(value: Color(white: 1), opacity: 0)
        let slgc3 = Composition(value: Color(white: 1), opacity: 1)
        let slgValues = [Gradient.Value(colorComposition: slgc0, location: 0),
                         Gradient.Value(colorComposition: slgc1, location: y),
                         Gradient.Value(colorComposition: slgc2, location: y),
                         Gradient.Value(colorComposition: slgc3, location: 1)]
        slBlackWhiteGradientView = View(gradient: Gradient(values: slgValues,
                                                           startPoint: Point(x: 0, y: 0),
                                                           endPoint: Point(x: 1, y: 0)))
        
        super.init(path: Path(), isLocked: false)
        lineColor = .content
        fillColor = binder[keyPath: keyPath]
        hueDrawView.fillColor = nil
        hueDrawView.lineColor = nil
        slBlackWhiteGradientView.lineColor = nil
        slColorGradientView.lineColor = nil
        hueDrawView.drawClosure = { [unowned self] ctx, _, _ in self.hueCircle.draw(in: ctx) }
        hueView.backgroundViews = [hueDrawView]
        slView.children = [slColorGradientView, slBlackWhiteGradientView, slView.knobView]
        children = [hueView, slView]
        
        hueView.notifications.append { [unowned self] (_, _) in self.updateGradient() }
        slView.notifications.append { [unowned self] (_, _) in self.updateGradient() }
        
        update(withBounds: Rect(origin: Point(), size: size))
    }
    
    let slSize = Size(width: 70, height: 20)
    let size = Size(square: 70)
    func update(withBounds bounds: Rect) {
        let r = bounds.width / 2
        let cp = bounds.centerPoint
        let hueSize = Size(width: r * 2, height: r * 2)
        let hueFrame = Rect(origin: Point(x: -hueSize.width / 2,
                                          y: -hueSize.height / 2),
                            size: hueSize)
        hueView.path = hueView.circularPath(withBounds: hueFrame)
        hueView.position = cp
        path = hueView.circularInternalPath(withBounds: hueFrame)
        position = cp
        
        let slFrame = Rect(origin: Point(x: 0, y: -hueFrame.minY - hueView.width),
                           size: size)
        slView.frame = slFrame
        let slInFrame = Rect(origin: Point(),
                             size: slFrame.size).inset(by: Layouter.movablePadding)
        slColorGradientView.frame = slInFrame
        slBlackWhiteGradientView.frame = slInFrame
        
        let hueDrawPadding = ((hueView.width - Layouter.movableLineWidth) / 2).rounded()
        let hueDrawFrame = hueFrame.inset(by: hueDrawPadding).integral
        hueDrawView.frame = hueDrawFrame
        hueCircle = HueCircle(lineWidth: Layouter.movableLineWidth,
                              bounds: Rect(origin: Point(), size: hueDrawFrame.size),
                              rgbColorSpace: model.rgbColorSpace)
        self.bounds = bounds
    }
    func updateWithModel() {
        if model.rgbColorSpace != hueCircle.rgbColorSpace {
            updateWithColorSpace()
        }
        hueView.updateWithModel()
        slView.updateWithModel()
        updateGradient()
    }
    private func updateGradient() {
        let y = Color.y(withHSLHue: model.hue)
        let cs = [Composition(value: Color(hue: model.hue, saturation: 0,
                                           lightnessFromMaxSaturation: y)),
                  Composition(value: Color(hue: model.hue, saturation: 1,
                                           lightnessFromMaxSaturation: 1))]
        slColorGradientView.gradient?.colorCompositions = cs
        slBlackWhiteGradientView.gradient?.locations = [0, y, y, 1]
        
        fillColor = model
    }
    private func updateWithColorSpace() {
        let cs = [Composition(value: Color(white: 0), opacity: 1),
                  Composition(value: Color(white: 0), opacity: 0),
                  Composition(value: Color(white: 1), opacity: 0),
                  Composition(value: Color(white: 1), opacity: 1)]
        slBlackWhiteGradientView.gradient?.colorCompositions = cs
        hueCircle = HueCircle(lineWidth: Layouter.movableLineWidth,
                              bounds: hueDrawView.bounds,
                              rgbColorSpace: model.rgbColorSpace)
    }
}
