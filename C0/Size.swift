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

import Foundation

struct Size: Equatable {
    var width = 0.0, height = 0.0
    
    func with(width: Double) -> Size {
        return Size(width: width, height: height)
    }
    func with(h: Double) -> Size {
        return Size(width: width, height: height)
    }
    
    var isEmpty: Bool {
        return width == 0 && height == 0
    }
    
    static func *(lhs: Size, rhs: Double) -> Size {
        return Size(width: lhs.width * rhs, height: lhs.height * rhs)
    }
}
extension Size: Hashable {
    var hashValue: Int {
        return Hash.uniformityHashValue(with: [width.hashValue, height.hashValue])
    }
}
extension Size: Codable {
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let width = try container.decode(Double.self)
        let height = try container.decode(Double.self)
        self.init(width: width, height: height)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(width)
        try container.encode(height)
    }
}
extension Size: Referenceable {
    static let name = Localization(english: "Size", japanese: "サイズ")
}

extension CGSize {
    static func *(lhs: CGSize, rhs: CGFloat) -> CGSize {
        return CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
    func with(width: CGFloat) -> CGSize {
        return CGSize(width: width, height: height)
    }
    func with(height: CGFloat) -> CGSize {
        return CGSize(width: width, height: height)
    }
    init(square: CGFloat) {
        self.init(width: square, height: square)
    }
    
    init(_ string: String) {
        self = NSSizeToCGSize(NSSizeFromString(string))
    }
    var string: String {
        return String(NSStringFromSize(NSSizeFromCGSize(self)))
    }
    
    static let effectiveFieldSizeOfView = CGSize(width: tan(.pi * (30.0 / 2) / 180),
                                                 height: tan(.pi * (20.0 / 2) / 180))
    
}
extension CGSize: Referenceable {
    static let name = Localization(english: "Size", japanese: "サイズ")
}
extension CGSize: ObjectViewExpression {
    func thumbnail(withBounds bounds: CGRect, sizeType: SizeType) -> Layer {
        return string.view(withBounds: bounds, sizeType: sizeType)
    }
}

final class DiscreteSizeView: View {
    var size = CGSize() {
        didSet {
            if size != oldValue {
                widthView.number = size.width
                heightView.number = size.height
            }
        }
    }
    var defaultSize = CGSize()
    
    var sizeType: SizeType
    let classWidthNameView: TextView
    let widthView: DiscreteNumberView
    let classHeightNameView: TextView
    let heightView: DiscreteNumberView
    init(sizeType: SizeType) {
        self.sizeType = sizeType
        
        classWidthNameView = TextView(text: Localization("w:"), font: Font.default(with: sizeType))
        widthView = DiscreteNumberView(frame: Layout.valueFrame, min: 1, max: 10000,
                                       numberInterval: 1, sizeType: sizeType)
        classHeightNameView = TextView(text: Localization("h:"), font: Font.default(with: sizeType))
        heightView = DiscreteNumberView(frame: Layout.valueFrame,
                                        min: 1, max: 10000, numberInterval: 1, sizeType: sizeType)
        
        super.init()
        replace(children: [classWidthNameView, widthView, classHeightNameView, heightView])
        widthView.binding = { [unowned self] in self.setSize(with: $0) }
        heightView.binding = { [unowned self] in self.setSize(with: $0) }
        updateLayout()
    }
    
    override var defaultBounds: CGRect {
        let padding = Layout.padding(with: sizeType), height = Layout.height(with: sizeType)
        return CGRect(x: 0, y: 0,
                      width: classWidthNameView.frame.width + widthView.frame.width + classHeightNameView.frame.width + heightView.frame.width + padding * 3,
                      height: height + padding * 2)
    }
    override var bounds: CGRect {
        didSet {
            updateLayout()
        }
    }
    func updateLayout() {
        let padding = Layout.padding(with: sizeType)
        var x = padding
        classWidthNameView.frame.origin = CGPoint(x: x, y: padding)
        x += classWidthNameView.frame.width
        widthView.frame.origin = CGPoint(x: x, y: padding)
        x += widthView.frame.width + padding
        classHeightNameView.frame.origin = CGPoint(x: x, y: padding)
        x += classHeightNameView.frame.width
        heightView.frame.origin = CGPoint(x: x, y: padding)
        x += heightView.frame.width + padding
    }
    
    struct Binding {
        let view: DiscreteSizeView
        let size: CGSize, oldSize: CGSize, type: Action.SendType
    }
    var binding: ((Binding) -> ())?
    
    var disabledRegisterUndo = false
    
    private var oldSize = CGSize()
    private func setSize(with obj: DiscreteNumberView.Binding) {
        if obj.type == .begin {
            oldSize = size
            binding?(Binding(view: self, size: oldSize, oldSize: oldSize, type: .begin))
        } else {
            size = obj.view == widthView ?
                size.with(width: obj.number) : size.with(height: obj.number)
            binding?(Binding(view: self, size: size, oldSize: oldSize, type: obj.type))
        }
    }
    
    func delete(with event: KeyInputEvent) -> Bool {
        let size = defaultSize
        if size != self.size {
            push(size, old: self.size)
        }
        return true
    }
    func copiedObjects(with event: KeyInputEvent) -> [ViewExpression]? {
        return [size, size.string]
    }
    func paste(_ objects: [Any], with event: KeyInputEvent) -> Bool {
        for object in objects {
            if let size = object as? CGSize {
                if size != self.size {
                    push(size, old: self.size)
                    return true
                }
            } else if let string = object as? String {
                let size = CGSize(string)
                if size != self.size {
                    push(size, old: self.size)
                    return true
                }
            }
        }
        return false
    }
    
    func push(_ size: CGSize, old oldSize: CGSize) {
        registeringUndoManager?.registerUndo(withTarget: self) { $0.push(oldSize, old: size) }
        binding?(Binding(view: self, size: size, oldSize: oldSize, type: .begin))
        self.size = size
        binding?(Binding(view: self, size: size, oldSize: oldSize, type: .end))
    }
    
    func reference(with event: TapEvent) -> Reference? {
        return size.reference
    }
}
