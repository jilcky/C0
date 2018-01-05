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

import Foundation
import QuartzCore

struct Transform: Codable {
    static let name = Localization(english: "Transform", japanese: "トランスフォーム")
    
    let translation: CGPoint, scale: CGPoint, rotation: CGFloat
    let z: CGFloat, affineTransform: CGAffineTransform
    
    init(translation: CGPoint = CGPoint(), z: CGFloat = 0, rotation: CGFloat = 0) {
        let pow2 = pow(2, z)
        self.translation = translation
        self.scale = CGPoint(x: pow2, y: pow2)
        self.z = z
        self.rotation = rotation
        self.affineTransform = Transform.affineTransform(translation: translation,
                                                         scale: scale, rotation: rotation)
    }
    init(translation: CGPoint = CGPoint(), scale: CGPoint, rotation: CGFloat = 0) {
        self.translation = translation
        self.z = log2(scale.x)
        self.scale = scale
        self.rotation = rotation
        self.affineTransform = Transform.affineTransform(translation: translation,
                                                         scale: scale, rotation: rotation)
    }
    init(translation: CGPoint, z: CGFloat, scale: CGPoint, rotation: CGFloat) {
        self.translation = translation
        self.z = z
        self.scale = scale
        self.rotation = rotation
        self.affineTransform = Transform.affineTransform(translation: translation,
                                                         scale: scale, rotation: rotation)
    }
    
    private static func affineTransform(translation: CGPoint,
                                        scale: CGPoint, rotation: CGFloat) -> CGAffineTransform {
        var affine = CGAffineTransform(translationX: translation.x, y: translation.y)
        if rotation != 0 {
            affine = affine.rotated(by: rotation)
        }
        if scale != CGPoint() {
            affine = affine.scaledBy(x: scale.x, y: scale.y)
        }
        return affine
    }
    
    func with(translation: CGPoint) -> Transform {
        return Transform(translation: translation, z: z, scale: scale, rotation: rotation)
    }
    func with(z: CGFloat) -> Transform {
        return Transform(translation: translation, z: z, rotation: rotation)
    }
    func with(scale: CGFloat) -> Transform {
        return Transform(translation: translation,
                         scale: CGPoint(x: scale, y: scale), rotation: rotation)
    }
    func with(scale: CGPoint) -> Transform {
        return Transform(translation: translation,
                         scale: scale, rotation: rotation)
    }
    func with(rotation: CGFloat) -> Transform {
        return Transform(translation: translation,
                         z: z, scale: scale, rotation: rotation)
    }
    
    var isIdentity: Bool {
        return translation == CGPoint() && scale == CGPoint(x: 1, y: 1) && rotation == 0
    }
}
extension Transform: Equatable {
    static func ==(lhs: Transform, rhs: Transform) -> Bool {
        return lhs.translation == rhs.translation
            && lhs.scale == rhs.scale && lhs.rotation == rhs.rotation
    }
}
extension Transform: Interpolatable {
    static func linear(_ f0: Transform, _ f1: Transform, t: CGFloat) -> Transform {
        let translation = CGPoint.linear(f0.translation, f1.translation, t: t)
        let scaleX = CGFloat.linear(f0.scale.x, f1.scale.x, t: t)
        let scaleY = CGFloat.linear(f0.scale.y, f1.scale.y, t: t)
        let rotation = CGFloat.linear(f0.rotation, f1.rotation, t: t)
        return Transform(translation: translation,
                         scale: CGPoint(x: scaleX, y: scaleY), rotation: rotation)
    }
    static func firstMonospline(_ f1: Transform, _ f2: Transform, _ f3: Transform,
                                with msx: MonosplineX) -> Transform {
        let translation = CGPoint.firstMonospline(f1.translation, f2.translation,
                                                  f3.translation, with: msx)
        let scaleX = CGFloat.firstMonospline(f1.scale.x, f2.scale.x, f3.scale.x, with: msx)
        let scaleY = CGFloat.firstMonospline(f1.scale.y, f2.scale.y, f3.scale.y, with: msx)
        let rotation = CGFloat.firstMonospline(f1.rotation, f2.rotation, f3.rotation, with: msx)
        return Transform(translation: translation,
                         scale: CGPoint(x: scaleX, y: scaleY), rotation: rotation)
    }
    static func monospline(_ f0: Transform, _ f1: Transform, _ f2: Transform, _ f3: Transform,
                           with msx: MonosplineX) -> Transform {
        let translation = CGPoint.monospline(f0.translation, f1.translation,
                                             f2.translation, f3.translation, with: msx)
        let scaleX = CGFloat.monospline(f0.scale.x, f1.scale.x,
                                        f2.scale.x, f3.scale.x, with: msx)
        let scaleY = CGFloat.monospline(f0.scale.y, f1.scale.y,
                                        f2.scale.y, f3.scale.y, with: msx)
        let rotation = CGFloat.monospline(f0.rotation, f1.rotation,
                                          f2.rotation, f3.rotation, with: msx)
        return Transform(translation: translation,
                         scale: CGPoint(x: scaleX, y: scaleY), rotation: rotation)
    }
    static func endMonospline(_ f0: Transform, _ f1: Transform, _ f2: Transform,
                              with msx: MonosplineX) -> Transform {
        
        let translation = CGPoint.endMonospline(f0.translation, f1.translation,
                                                f2.translation, with: msx)
        let scaleX = CGFloat.endMonospline(f0.scale.x, f1.scale.x, f2.scale.x, with: msx)
        let scaleY = CGFloat.endMonospline(f0.scale.y, f1.scale.y, f2.scale.y, with: msx)
        let rotation = CGFloat.endMonospline(f0.rotation, f1.rotation, f2.rotation, with: msx)
        return Transform(translation: translation,
                         scale: CGPoint(x: scaleX, y: scaleY), rotation: rotation)
    }
}

final class TransformEditor: LayerRespondable, Localizable {
    static let name = Localization(english: "Transform Editor", japanese: "トランスフォームエディタ")
    
    weak var parent: Respondable?
    var children = [Respondable]() {
        didSet {
            update(withChildren: children, oldChildren: oldValue)
        }
    }
    
    var locale = Locale.current {
        didSet {
            updateLayout()
        }
    }
    
    static let valueWidth = 50.0.cf
    static let valueFrame = CGRect(x: 0, y: Layout.basicPadding,
                                   width: valueWidth, height: Layout.basicHeight)
    
    private let nameLabel = Label(text: Transform.name, font: .bold)
    private let xLabel = Label(text: Localization("x:"))
    private let yLabel = Label(text: Localization("y:"))
    private let zLabel = Label(text: Localization("z:"))
    private let thetaLabel = Label(text: Localization("θ:"))
    private let xSlider = NumberSlider(frame: TransformEditor.valueFrame,
                                       min: -10000, max: 10000, valueInterval: 0.01,
                                       description: Localization(english: "Translation x",
                                                                 japanese: "移動 x"))
    private let ySlider = NumberSlider(frame: TransformEditor.valueFrame,
                                       min: -10000, max: 10000, valueInterval: 0.01,
                                       description: Localization(english: "Translation y",
                                                                 japanese: "移動 y"))
    private let zSlider = NumberSlider(frame: TransformEditor.valueFrame,
                                       min: -20, max: 20, valueInterval: 0.01,
                                       description: Localization(english: "Translation z",
                                                                 japanese: "移動 z"))
    private let thetaSlider = NumberSlider(frame: TransformEditor.valueFrame,
                                           min: -10000, max: 10000, valueInterval: 0.5, unit: "°",
                                           description: Localization(english: "Angle",
                                                                     japanese: "角度"))
    let layer = CALayer.interface()
    init() {
        let children: [Respondable] = [nameLabel, xLabel, xSlider, yLabel, ySlider, zLabel, zSlider,
                                       thetaLabel, thetaSlider]
        self.children = children
        update(withChildren: children, oldChildren: [])
        xSlider.setValueHandler = { [unowned self] in self.setTransform(with: $0) }
        ySlider.setValueHandler = { [unowned self] in self.setTransform(with: $0) }
        zSlider.setValueHandler = { [unowned self] in self.setTransform(with: $0) }
        thetaSlider.setValueHandler = { [unowned self] in self.setTransform(with: $0) }
    }
    
    var frame: CGRect {
        get {
            return layer.frame
        }
        set {
            layer.frame = newValue
            updateLayout()
        }
    }
    func updateLayout() {
        let children: [Respondable] = [nameLabel, Padding(),
                                       xLabel, xSlider, Padding(), yLabel, ySlider, Padding(),
                                       zLabel, zSlider, Padding(), thetaLabel, thetaSlider]
        _ = Layout.leftAlignment(children, height: frame.height)
    }
    var editBounds: CGRect {
        let children: [Respondable] = [nameLabel, Padding(),
                                       xLabel, xSlider, Padding(), yLabel, ySlider, Padding(),
                                       zLabel, zSlider, Padding(), thetaLabel, thetaSlider]
        return CGRect(x: 0,
                      y: 0,
                      width: Layout.leftAlignmentWidth(children) + Layout.basicPadding,
                      height: Layout.basicHeight)
    }
    
    var standardTranslation = CGPoint(x: 1, y: 1)
    
    var transform = Transform() {
        didSet {
            if transform != oldValue {
                updateChildren()
            }
        }
    }
    private func updateChildren() {
        xSlider.value = transform.translation.x / standardTranslation.x
        ySlider.value = transform.translation.y / standardTranslation.y
        zSlider.value = transform.z
        thetaSlider.value = transform.rotation * 180 / (.pi)
    }
    
    var isLocked = false {
        didSet {
            xSlider.isLocked = isLocked
            ySlider.isLocked = isLocked
            zSlider.isLocked = isLocked
            thetaSlider.isLocked = isLocked
        }
    }
    
    var disabledRegisterUndo = true
    
    struct HandlerObject {
        let transformEditor: TransformEditor
        let transform: Transform, oldTransform: Transform, type: Action.SendType
    }
    var setTransformHandler: ((HandlerObject) -> ())?
    
    private var oldTransform = Transform()
    private func setTransform(with obj: NumberSlider.HandlerObject) {
        if obj.type == .begin {
            oldTransform = transform
            setTransformHandler?(HandlerObject(transformEditor: self,
                                               transform: oldTransform,
                                               oldTransform: oldTransform, type: .begin))
        } else {
            switch obj.slider {
            case xSlider:
                transform = transform.with(translation: CGPoint(x: obj.value * standardTranslation.x,
                                                                y: transform.translation.y))
            case ySlider:
                transform = transform.with(translation: CGPoint(x: transform.translation.x,
                                                                y: obj.value * standardTranslation.y))
            case zSlider:
                transform = transform.with(z: obj.value)
            case thetaSlider:
                transform = transform.with(rotation: obj.value * (.pi / 180))
            default:
                fatalError()
            }
            setTransformHandler?(HandlerObject(transformEditor: self,
                                               transform: transform,
                                               oldTransform: oldTransform, type: obj.type))
        }
    }
    
    func copy(with event: KeyInputEvent) -> CopiedObject {
        return CopiedObject(objects: [transform])
    }
    func paste(_ copiedObject: CopiedObject, with event: KeyInputEvent) {
        guard !isLocked else {
            return
        }
        for object in copiedObject.objects {
            if let transform = object as? Transform {
                guard transform != self.transform else {
                    continue
                }
                set(transform, oldTransform: self.transform)
                return
            }
        }
    }
    func delete(with event: KeyInputEvent) {
        guard !isLocked else {
            return
        }
        let transform = Transform()
        guard transform != self.transform else {
            return
        }
        set(transform, oldTransform: self.transform)
    }
    
    func set(_ transform: Transform, oldTransform: Transform) {
        registeringUndoManager?.registerUndo(withTarget: self) {
            $0.set(oldTransform, oldTransform: transform)
        }
        setTransformHandler?(HandlerObject(transformEditor: self,
                                           transform: oldTransform, oldTransform: oldTransform,
                                           type: .begin))
        self.transform = transform
        setTransformHandler?(HandlerObject(transformEditor: self,
                                           transform: transform, oldTransform: oldTransform,
                                           type: .end))
    }
}

typealias Hz = CGFloat
struct Wiggle: Codable {
    var amplitude = CGPoint(), frequency = Hz(8)
    
    func with(amplitude: CGPoint) -> Wiggle {
        return Wiggle(amplitude: amplitude, frequency: frequency)
    }
    func with(frequency: Hz) -> Wiggle {
        return Wiggle(amplitude: amplitude, frequency: frequency)
    }
    
    var isEmpty: Bool {
        return amplitude == CGPoint()
    }
    func phasePosition(with position: CGPoint, phase: CGFloat) -> CGPoint {
        let x = sin(2 * (.pi) * phase)
        return CGPoint(x: position.x + amplitude.x * x, y: position.y + amplitude.y * x)
    }
}
extension Wiggle: Equatable {
    static func ==(lhs: Wiggle, rhs: Wiggle) -> Bool {
        return lhs.amplitude == rhs.amplitude && lhs.frequency == rhs.frequency
    }
}
extension Wiggle: Interpolatable {
    static func linear(_ f0: Wiggle, _ f1: Wiggle, t: CGFloat) -> Wiggle {
        let amplitude = CGPoint.linear(f0.amplitude, f1.amplitude, t: t)
        let frequency = CGFloat.linear(f0.frequency, f1.frequency, t: t)
        return Wiggle(amplitude: amplitude, frequency: frequency)
    }
    static func firstMonospline(_ f1: Wiggle, _ f2: Wiggle,
                                _ f3: Wiggle, with msx: MonosplineX) -> Wiggle {
        let amplitude = CGPoint.firstMonospline(f1.amplitude, f2.amplitude, f3.amplitude, with: msx)
        let frequency = CGFloat.firstMonospline(f1.frequency, f2.frequency, f3.frequency, with: msx)
        return Wiggle(amplitude: amplitude, frequency: frequency)
    }
    static func monospline(_ f0: Wiggle, _ f1: Wiggle,
                           _ f2: Wiggle, _ f3: Wiggle, with msx: MonosplineX) -> Wiggle {
        let amplitude = CGPoint.monospline(f0.amplitude, f1.amplitude,
                                           f2.amplitude, f3.amplitude, with: msx)
        let frequency = CGFloat.monospline(f0.frequency, f1.frequency,
                                           f2.frequency, f3.frequency, with: msx)
        return Wiggle(amplitude: amplitude, frequency: frequency)
    }
    static func endMonospline(_ f0: Wiggle, _ f1: Wiggle,
                              _ f2: Wiggle, with msx: MonosplineX) -> Wiggle {
        let amplitude = CGPoint.endMonospline(f0.amplitude, f1.amplitude, f2.amplitude, with: msx)
        let frequency = CGFloat.endMonospline(f0.frequency, f1.frequency, f2.frequency, with: msx)
        return Wiggle(amplitude: amplitude, frequency: frequency)
    }
}
extension Wiggle: Referenceable {
    static let name = Localization(english: "Wiggle", japanese: "振動")
}

final class WiggleEditor: LayerRespondable, Localizable {
    static let name = Localization(english: "Wiggle Editor", japanese: "振動エディタ")
    
    weak var parent: Respondable?
    var children = [Respondable]() {
        didSet {
            update(withChildren: children, oldChildren: oldValue)
        }
    }
    
    var locale = Locale.current {
        didSet {
            updateLayout()
        }
    }
    
    static let valueWidth = 50.0.cf
    static let valueFrame = CGRect(x: 0, y: Layout.basicPadding,
                                   width: valueWidth, height: Layout.basicHeight)
    
    private let nameLabel = Label(text: Wiggle.name, font: .bold)
    private let xLabel = Label(text: Localization("x:"))
    private let yLabel = Label(text: Localization("y:"))
    private let xSlider = NumberSlider(frame: WiggleEditor.valueFrame,
                                       min: 0, max: 1000, valueInterval: 0.01,
                                       description: Localization(english: "Amplitude x",
                                                                 japanese: "振幅 x"))
    private let ySlider = NumberSlider(frame: WiggleEditor.valueFrame,
                                       min: 0, max: 1000, valueInterval: 0.01,
                                       description: Localization(english: "Amplitude y",
                                                                 japanese: "振幅 y"))
    private let frequencySlider = NumberSlider(frame: WiggleEditor.valueFrame,
                                               min: 0.1, max: 100000, valueInterval: 0.1, unit: " Hz",
                                               description: Localization(english: "Frequency",
                                                                         japanese: "振動数"))
    let layer = CALayer.interface()
    init() {
        let children: [Respondable] = [nameLabel, xLabel, xSlider, yLabel, ySlider, frequencySlider]
        self.children = children
        update(withChildren: children, oldChildren: [])
        frequencySlider.defaultValue = wiggle.frequency
        frequencySlider.value = wiggle.frequency
        
        xSlider.setValueHandler = { [unowned self] in self.setWiggle(with: $0) }
        ySlider.setValueHandler = { [unowned self] in self.setWiggle(with: $0) }
        frequencySlider.setValueHandler = { [unowned self] in self.setWiggle(with: $0) }
    }
    
    var isLocked = false {
        didSet {
            xSlider.isLocked = isLocked
            ySlider.isLocked = isLocked
            frequencySlider.isLocked = isLocked
        }
    }
    
    func updateLayout() {
        let children: [Respondable] = [nameLabel, Padding(), xLabel, xSlider, Padding(),
                                       yLabel, ySlider, frequencySlider]
        _ = Layout.leftAlignment(children, height: frame.height)
    }
    
    var standardAmplitude = CGPoint(x: 1, y: 1)
    
    var frame: CGRect {
        get {
            return layer.frame
        }
        set {
            layer.frame = newValue
            updateLayout()
        }
    }
    var editBounds: CGRect {
        let children: [Respondable] = [nameLabel, Padding(), xLabel, xSlider, Padding(),
                                       yLabel, ySlider, frequencySlider]
        return CGRect(x: 0,
                      y: 0,
                      width: Layout.leftAlignmentWidth(children) + Layout.basicPadding,
                      height: Layout.basicHeight)
    }
    
    var wiggle = Wiggle() {
        didSet {
            if wiggle != oldValue {
                updateChildren()
            }
        }
    }
    private func updateChildren() {
        xSlider.value = 10 * wiggle.amplitude.x / standardAmplitude.x
        ySlider.value = 10 * wiggle.amplitude.y / standardAmplitude.y
        frequencySlider.value = wiggle.frequency
    }
    
    var disabledRegisterUndo = true
    
    struct HandlerObject {
        let wiggleEditor: WiggleEditor
        let wiggle: Wiggle, oldWiggle: Wiggle, type: Action.SendType
    }
    var setWiggleHandler: ((HandlerObject) -> ())?
    
    private var oldWiggle = Wiggle()
    private func setWiggle(with obj: NumberSlider.HandlerObject) {
        if obj.type == .begin {
            oldWiggle = wiggle
            setWiggleHandler?(HandlerObject(wiggleEditor: self,
                                            wiggle: oldWiggle,
                                            oldWiggle: oldWiggle, type: .begin))
        } else {
            switch obj.slider {
            case xSlider:
                wiggle = wiggle.with(amplitude: CGPoint(x: obj.value * standardAmplitude.x / 10,
                                                        y: wiggle.amplitude.y))
            case ySlider:
                wiggle = wiggle.with(amplitude: CGPoint(x: wiggle.amplitude.x,
                                                        y: obj.value * standardAmplitude.y / 10))
            case frequencySlider:
                wiggle = wiggle.with(frequency: obj.value)
            default:
                fatalError()
            }
            setWiggleHandler?(HandlerObject(wiggleEditor: self,
                                            wiggle: wiggle,
                                            oldWiggle: oldWiggle, type: obj.type))
        }
    }
    
    func copy(with event: KeyInputEvent) -> CopiedObject {
        return CopiedObject(objects: [wiggle])
    }
    func paste(_ copiedObject: CopiedObject, with event: KeyInputEvent) {
        guard !isLocked else {
            return
        }
        for object in copiedObject.objects {
            if let wiggle = object as? Wiggle {
                guard wiggle != self.wiggle else {
                    continue
                }
                set(wiggle, oldWiggle: self.wiggle)
                return
            }
        }
    }
    func delete(with event: KeyInputEvent) {
        guard !isLocked else {
            return
        }
        let wiggle = Wiggle()
        guard wiggle != self.wiggle else {
            return
        }
        set(wiggle, oldWiggle: self.wiggle)
    }
    
    func set(_ wiggle: Wiggle, oldWiggle: Wiggle) {
        registeringUndoManager?.registerUndo(withTarget: self) {
            $0.set(oldWiggle, oldWiggle: wiggle)
        }
        setWiggleHandler?(HandlerObject(wiggleEditor: self,
                                        wiggle: oldWiggle, oldWiggle: oldWiggle,
                                        type: .begin))
        self.wiggle = wiggle
        setWiggleHandler?(HandlerObject(wiggleEditor: self,
                                        wiggle: wiggle, oldWiggle: oldWiggle,
                                        type: .end))
    }
}