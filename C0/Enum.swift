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

typealias EnumType = RawRepresentable & Referenceable & Viewable & Equatable

final class EnumView<T: EnumType>: View, Queryable, Assignable, Runnable, Movable {
    var enumeratedType: T {
        didSet {
            index = indexClosure(enumeratedType.rawValue)
        }
    }
    private(set) var index = 0 {
        didSet {
            if index != oldValue {
                updateWithEnumeratedType()
                updateLayout()
            }
        }
    }
    var defaultEnumeratedType: T
    var cationEnumeratedType: T? {
        didSet {
            if let cationEnumeratedType = cationEnumeratedType {
                cationIndex = indexClosure(cationEnumeratedType.rawValue)
            } else {
                cationIndex = nil
            }
        }
    }
    private var cationIndex: Int?
    
    var indexClosure: ((T.RawValue) -> (Int))
    var rawValueClosure: ((Int) -> (T.RawValue?))
    
    var sizeType: SizeType
    let classNameView: TextView
    let knobView: DiscreteKnobView
    private let lineView: View = {
        let lineView = View(path: CGMutablePath())
        lineView.fillColor = .content
        return lineView
    } ()
    var classNameViews: [TextView]
    
    init(enumeratedType: T, defaultEnumeratedType: T? = nil,
         cationEnumeratedType: T? = nil,
         indexClosure: @escaping ((T.RawValue) -> (Int)) = { $0 as? Int ?? 0 },
         rawValueClosure: @escaping ((Int) -> (T.RawValue?)) = { $0 as? T.RawValue },
         frame: Rect = Rect(),
         names: [Text] = [], sizeType: SizeType = .regular) {
        
        classNameView = TextView(text: T.uninheritanceName, font: Font.bold(with: sizeType))
        self.enumeratedType = enumeratedType
        self.defaultEnumeratedType = defaultEnumeratedType ?? enumeratedType
        self.cationEnumeratedType = cationEnumeratedType
        self.indexClosure = indexClosure
        self.rawValueClosure = rawValueClosure
        index = indexClosure(enumeratedType.rawValue)
        if let cationEnumeratedType = cationEnumeratedType {
            cationIndex = indexClosure(cationEnumeratedType.rawValue)
        }
        
        classNameViews = names.map { TextView(text: $0, font: Font.default(with: sizeType)) }
        self.knobView = sizeType == .small ?
            DiscreteKnobView(Size(square: 6), lineWidth: 1) :
            DiscreteKnobView(Size(square: 8), lineWidth: 1)
        self.sizeType = sizeType
        
        super.init()
        self.frame = frame
        children = [classNameView, lineView, knobView] + classNameViews
        updateLayout()
        updateWithEnumeratedType()
    }
    
    override var locale: Locale {
        didSet {
            updateLayout()
        }
    }
    
    override var defaultBounds: Rect {
        let padding = Layout.padding(with: sizeType), height = Layout.height(with: sizeType)
        let nw = classNameViews.reduce(0.0.cg) { $0 + $1.frame.width } + Real(classNameViews.count - 1) * padding
        return Rect(x: 0, y: 0, width: classNameView.frame.width + nw + padding * 2, height: height)
    }
    override var bounds: Rect {
        didSet {
            updateLayout()
        }
    }
    private func updateLayout() {
        let padding = Layout.padding(with: sizeType)
        classNameView.frame.origin = Point(x: padding,
                                             y: bounds.height - classNameView.frame.height - padding)
        let path = CGMutablePath()
        let h = Layout.height(with: sizeType) - padding * 2
        var y = bounds.height - padding - h
        _ = classNameViews.reduce(classNameView.frame.maxX + padding) {
            let x: Real
            if $0 + $1.frame.width + padding > bounds.width {
                x = padding
                y -= h + padding
            } else {
                x = $0
            }
            $1.frame.origin = Point(x: x, y: y)
            path.addRect($1.frame)
            return x + $1.frame.width + padding
        }
        lineView.path = path
        
        knobView.frame = classNameViews[index].frame.inset(by: -1)
    }
    private func updateWithEnumeratedType() {
        knobView.frame = classNameViews[index].frame.inset(by: -1)
        classNameViews.forEach {
            $0.fillColor = .background
            $0.lineColor = .subContent
        }
        classNameViews[index].fillColor = .knob
        classNameViews[index].lineColor = .knob
        classNameViews.enumerated().forEach {
            $0.element.textFrame.color = $0.offset == index ? .locked : .subLocked
        }
    }
    
    func enumeratedType(at index: Int) -> T {
        if let rawValue = rawValueClosure(index) {
            return T(rawValue: rawValue) ?? defaultEnumeratedType
        } else {
            return defaultEnumeratedType
        }
    }
    func enumeratedType(at p: Point) -> T {
        var minI = 0, minD = Real.infinity
        for (i, view) in classNameViews.enumerated() {
            let d = view.frame.distance²(p)
            if d < minD {
                minI = i
                minD = d
            }
        }
        return enumeratedType(at: minI)
    }
    
    struct Binding {
        let view: EnumView, enumeratedType: T, oldEnumeratedType: T, phase: Phase
    }
    var binding: ((Binding) -> ())?
    
    var disabledRegisterUndo = false
    
    func delete(for p: Point) {
        let enumeratedType = defaultEnumeratedType
        if enumeratedType != self.enumeratedType {
            push(enumeratedType, old: self.enumeratedType)
        }
    }
    func copiedViewables(at p: Point) -> [Viewable] {
        return [enumeratedType]
    }
    func paste(_ objects: [Any], for p: Point) {
        for object in objects {
            if let enumeratedType = object as? T {
                if enumeratedType != self.enumeratedType {
                    push(enumeratedType, old: self.enumeratedType)
                    return
                }
            } else if let string = object as? String, let index = Int(string) {
                let enumeratedType = self.enumeratedType(at: index)
                if enumeratedType != self.enumeratedType {
                    push(enumeratedType, old: self.enumeratedType)
                    return
                }
            }
        }
    }
    func push(_ enumeratedType: T, old oldEnumeratedType: T) {
        registeringUndoManager?.registerUndo(withTarget: self) {
            $0.push(oldEnumeratedType, old: enumeratedType)
        }
        binding?(Binding(view: self, enumeratedType: oldEnumeratedType,
                         oldEnumeratedType: oldEnumeratedType, phase: .began))
        self.enumeratedType = enumeratedType
        binding?(Binding(view: self, enumeratedType: enumeratedType,
                         oldEnumeratedType: oldEnumeratedType, phase: .ended))
    }
    
    func run(for p: Point) {
        let enumeratedType = self.enumeratedType(at: p)
        if enumeratedType != self.enumeratedType {
            push(enumeratedType, old: self.enumeratedType)
        }
    }
    
    private var oldEnumeratedType: T?, oldPoint = Point()
    func move(for p: Point, pressure: Real, time: Second, _ phase: Phase) {
        switch phase {
        case .began:
            knobView.fillColor = .editing
            let oldEnumeratedType = enumeratedType
            self.oldEnumeratedType = oldEnumeratedType
            oldPoint = p
            binding?(Binding(view: self, enumeratedType: enumeratedType,
                             oldEnumeratedType: oldEnumeratedType, phase: .began))
            enumeratedType = self.enumeratedType(at: p)
            binding?(Binding(view: self, enumeratedType: enumeratedType,
                             oldEnumeratedType: oldEnumeratedType, phase: .changed))
        case .changed:
            guard let oldEnumeratedType = oldEnumeratedType else {
                return
            }
            enumeratedType = self.enumeratedType(at: p)
            binding?(Binding(view: self, enumeratedType: enumeratedType,
                             oldEnumeratedType: oldEnumeratedType, phase: .changed))
        case .ended:
            guard let oldEnumeratedType = oldEnumeratedType else {
                return
            }
            enumeratedType = self.enumeratedType(at: p)
            if enumeratedType != oldEnumeratedType {
                registeringUndoManager?.registerUndo(withTarget: self) {
                    [enumeratedType, oldEnumeratedType] in
                    
                    $0.push(oldEnumeratedType, old: enumeratedType)
                }
            }
            binding?(Binding(view: self, enumeratedType: enumeratedType,
                             oldEnumeratedType: oldEnumeratedType, phase: .ended))
            knobView.fillColor = .knob
        }
    }
    
    func reference(at p: Point) -> Reference {
        return T.reference
    }
}
