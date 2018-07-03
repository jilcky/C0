/*
 Copyright 2018 S
 
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

extension Bool: Referenceable {
    static let name = Text(english: "Bool", japanese: "ブール値")
}
extension Bool: AnyInitializable {
    init?(anyValue: Any) {
        switch anyValue {
        case let value as Bool: self = value
        case let value as Int: self = value > 0
        case let value as Real: self = value > 0
        case let value as String:
            if let model = Bool(value) {
                self = model
            } else {
                return nil
            }
        case let valueChain as ValueChain:
            if let value = Bool(anyValue: valueChain.rootChainValue) {
                self = value
            } else {
                return nil
            }
        default: return nil
        }
    }
}
extension Bool: ThumbnailViewable {
    func thumbnailView(withFrame frame: Rect) -> View {
        let boolInfo = BoolOption.Info()
        let text = self ? boolInfo.trueName : boolInfo.falseName
        return text.thumbnailView(withFrame: frame)
    }
}
extension Bool: Viewable {
    func standardViewWith<T: BinderProtocol>
        (binder: T, keyPath: ReferenceWritableKeyPath<T, Bool>) -> ModelView {
        
        return BoolView(binder: binder, keyPath: keyPath, option: BoolOption())
    }
}
extension Bool: ObjectViewable {}

struct BoolOption {
    struct Info {
        var trueName = Text(english: "True", japanese: "真")
        var falseName = Text(english: "False", japanese: "偽")
        
        static let hidden = Info(trueName: Text(english: "Hidden", japanese: "隠し済み"),
                                 falseName: Text(english: "Shown", japanese: "表示済み"))
        static let locked = Info(trueName: Text(english: "Locked", japanese: "ロックあり"),
                                 falseName: Text(english: "Unlocked", japanese: "ロックなし"))
    }
    
    var cationModel: Bool?
    var name = Text()
    var info = Info()
}

final class BoolView<Binder: BinderProtocol>: ModelView, BindableReceiver {
    typealias Model = Bool
    typealias ModelOption = BoolOption
    typealias BinderKeyPath = ReferenceWritableKeyPath<Binder, Model>
    var binder: Binder {
        didSet { updateWithModel() }
    }
    var keyPath: BinderKeyPath {
        didSet { updateWithModel() }
    }
    var notifications = [((BoolView<Binder>, BasicPhaseNotification<Model>) -> ())]()
    
    var option: ModelOption {
        didSet {
            optionStringView.text = option.name
            optionTrueNameView.text = option.info.trueName
            optionFalseNameView.text = option.info.falseName
            updateWithModel()
        }
    }
    
    let optionStringView: TextFormView
    let optionTrueNameView: TextFormView
    let optionFalseNameView: TextFormView
    let knobView: View
    
    init(binder: Binder, keyPath: BinderKeyPath, option: ModelOption = ModelOption()) {
        self.binder = binder
        self.keyPath = keyPath
        self.option = option
        
        let font = Font.default
        optionStringView = TextFormView(text: option.name.isEmpty ? "" : option.name + ":",
                                        font: font)
        optionTrueNameView = TextFormView(text: option.info.trueName, font: font, paddingSize: Size(width: 4, height: 1))
        optionFalseNameView = TextFormView(text: option.info.falseName, font: font, paddingSize: Size(width: 4, height: 1))
        optionTrueNameView.fillColor = nil
        optionFalseNameView.fillColor = nil
        knobView = View.discreteKnob()
        
        super.init(isLocked: false)
        children = [optionStringView, knobView, optionTrueNameView, optionFalseNameView]
        updateWithModel()
    }
    
    var minSize: Size {
        let padding = Layouter.basicPadding
        let minTrueSize = optionTrueNameView.minSize
        let minFalseSize = optionFalseNameView.minSize
        if option.name.isEmpty {
            let width = minTrueSize.width + minFalseSize.width + padding * 3
            let height = max(minTrueSize.height, minFalseSize.height) + padding * 2
            return Size(width: width, height: height)
        } else {
            let minStringSize = optionStringView.minSize
            let width = minStringSize.width + minTrueSize.width + minFalseSize.width + padding * 4
            let height = max(minStringSize.height,
                             minTrueSize.height, minFalseSize.height) + padding * 2
            return Size(width: width, height: height)
        }
    }
    override func updateLayout() {
        let padding = Layouter.basicPadding
        let minTrueSize = optionTrueNameView.minSize
        let minFalseSize = optionFalseNameView.minSize
        var x = padding
        if !option.name.isEmpty {
            let minStringSize = optionStringView.minSize
            optionStringView.frame = Rect(origin: Point(x: x, y: padding), size: minStringSize)
            x += minStringSize.width + padding
        }
        optionFalseNameView.frame = Rect(origin: Point(x: x, y: padding), size: minFalseSize)
        x += minFalseSize.width + padding
        optionTrueNameView.frame = Rect(origin: Point(x: x, y: padding), size: minTrueSize)
        
        updateKnobLayout()
    }
    private func updateKnobLayout() {
        knobView.frame = model ? optionTrueNameView.frame : optionFalseNameView.frame
    }
    func updateWithModel() {
        updateKnobLayout()
        if option.cationModel != nil {
            knobView.lineColor = knobLineColor
        }
        optionFalseNameView.lineColor = model ? .subContent : nil
        optionTrueNameView.lineColor = model ? nil : .subContent
        optionFalseNameView.textMaterial.color = model ? .subLocked : .locked
        optionTrueNameView.textMaterial.color = model ? .locked : .subLocked
    }
    
    var knobLineColor: Color {
        return option.cationModel == model ? .warning : .getSetBorder
    }
    func model(at p: Point) -> Bool {
        let trueFrame = optionTrueNameView.frame
        let falseFrame = optionFalseNameView.frame
        return falseFrame.distance²(p) > trueFrame.distance²(p)
    }
}
extension BoolView: Runnable {
    func run(for p: Point, _ version: Version) {
        let model = self.model(at: p)
        push(model, to: version)
    }
}
extension BoolView: BasicPointMovable {
    func didChangeFromMovePoint(_ phase: Phase, beganModel: Model) {
        notifications.forEach { $0(self, .didChangeFromPhase(phase, beginModel: beganModel)) }
    }
}
