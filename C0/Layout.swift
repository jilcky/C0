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

enum Orientation {
    enum Horizontal {
        case leftToRight, rightToLeft
    }
    enum Vertical {
        case bottomToTop, topToBottom
    }
    enum XY {
        case horizontal(Horizontal), vertical(Vertical)
    }
    enum Circular {
        case clockwise, counterClockwise
    }
    
    case xy(XY), circular(Circular)
}

typealias LayoutValue = Codable & ThumbnailViewable & Referenceable & Viewable

protocol Layoutable {
    var frame: Rect { get set }
    var transform: Transform { get set }
}

protocol LayoutMinSize {
    func updateMinSize()
    var minSize: Size { get }
}

enum ConstraintType {
    case none, width, height, widthAndHeight
}

protocol LayoutProtocol {
    var transform: Transform { get set }
}
struct Layout<Value: LayoutValue>: Codable, LayoutProtocol {
    var value: Value
    var transform: Transform
    
    init(_ value: Value, transform: Transform = Transform()) {
        self.value = value
        self.transform = transform
    }
}
extension Layout: ValueChain {
    var chainValue: Any { return value }
}
extension Layout: AnyInitializable {
    init?(anyValue: Any) {
        if let value = (anyValue as? ValueChain)?.value(Value.self) {
            self = Layout(value)
        } else if let value = anyValue as? Value {
            self = Layout(value)
        } else {
            return nil
        }
    }
}
extension Layout: Referenceable {
    static var name: Text {
        return Text(english: "Layout", japanese: "レイアウト") + "<" + Value.name + ">"
    }
}
extension Layout: ThumbnailViewable {
    func thumbnailView(withFrame frame: Rect) -> View {
        return value.thumbnailView(withFrame: frame)
    }
}
extension Layout: Viewable {
    func standardViewWith<T: BinderProtocol>
        (binder: T, keyPath: ReferenceWritableKeyPath<T, Layout<Value>>) -> ModelView {
        
        return LayoutView(binder: binder, keyPath: keyPath)
    }
}
extension Layout: ObjectViewable {}

enum Layouter {
    static let smallPadding = 2.0.cg, basicPadding = 3.0.cg, basicLargePadding = 14.0.cg
    static let defaultMinWidth = 30.0.cg
    static let smallRatio = Font.small.size / Font.default.size
    static let basicTextHeight = Font.default.ceilHeight(withPadding: 1)
    static let basicTextSmallHeight = Font.small.ceilHeight(withPadding: 1)
    static let basicHeight = basicTextHeight + basicPadding * 2
    static let smallHeight = Font.small.ceilHeight(withPadding: 1) + smallPadding * 2
    static let basicValueWidth = 80.cg, smallValueWidth = 40.0.cg
    static let basicValueFrame = Rect(x: 0, y: basicPadding,
                                      width: basicValueWidth, height: basicHeight)
    static let smallValueFrame = Rect(x: 0, y: smallPadding,
                                      width: smallValueWidth, height: smallHeight)
    static let propertyWidth = 150.0.cg
    
    enum Item {
        case view(View & LayoutMinSize), xPadding(Real), yPadding(Real)
        
        var view: View? {
            switch self {
            case .view(let view): return view
            default: return nil
            }
        }
        var width: Real {
            switch self {
            case .view(let view): return view.transformedBoundingBox.width
            case .xPadding(let padding): return padding
            case .yPadding: return 0
            }
        }
        var height: Real {
            switch self {
            case .view(let view): return view.transformedBoundingBox.height
            case .xPadding: return 0
            case .yPadding(let padding): return padding
            }
        }
        var minWidth: Real {
            switch self {
            case .view(let view): return view.minSize.width
            case .xPadding(let padding): return padding
            case .yPadding: return 0
            }
        }
        var minHeight: Real {
            switch self {
            case .view(let view): return view.minSize.height
            case .xPadding: return 0
            case .yPadding(let padding): return padding
            }
        }
        var minSize: Size {
            switch self {
            case .view(let view): return view.minSize
            case .xPadding(let padding): return Size(width: padding, height: 0)
            case .yPadding(let padding): return Size(width: 0, height: padding)
            }
        }
    }
    
    static func centered(_ items: [Item],
                         in bounds: Rect, paddingWidth: Real = 0) {
        let w = items.reduce(-paddingWidth) { $0 +  $1.width + paddingWidth }
        _ = items.reduce(((bounds.width - w) / 2).rounded(.down)) { x, item in
            item.view?.frame.origin.x = x
            return x + item.minWidth + paddingWidth
        }
    }
    static func leftAlignmentWidth(_ items: [Item], minX: Real = basicPadding,
                                   paddingWidth: Real = 0) -> Real {
        return items.reduce(minX) { $0 + $1.width + paddingWidth } - paddingWidth
    }
    static func leftAlignment(_ items: [Item], minX: Real = basicPadding,
                              y: Real = 0, height: Real, paddingWidth: Real = 0) -> Size {
        let width = items.reduce(minX) { x, item in
            let minSize = item.minSize
            item.view?.frame = Rect(origin: Point(x: x,
                                                  y: y + ((height - minSize.height) / 2).rounded()),
                                    size: minSize)
            return x + minSize.width + paddingWidth
        }
        return Size(width: width, height: height)
    }
    static func topAlignment(_ items: [Item],
                             minX: Real = basicPadding, minY: Real = basicPadding,
                             minSize: inout Size, padding: Real = Layouter.basicPadding) {
        let width = items.reduce(0.0.cg) { max($0, $1.minWidth) } + padding * 2
        let height = items.reversed().reduce(minY) { y, item in
            item.view?.frame = Rect(x: minX, y: y, width: width, height: item.height)
            return y + item.minHeight
        }
        minSize = Size(width: width, height: height - minY)
    }
    static func autoHorizontalAlignment(_ items: [Item],
                                        padding: Real = 0, in bounds: Rect) {
        guard !items.isEmpty else { return }
        let w = items.reduce(0.0.cg) { $0 +  $1.minWidth + padding } - padding
        let dx = (bounds.width - w) / Real(items.count)
        _ = items.enumerated().reduce(bounds.minX) { x, value in
            let (i, item) = value
            if i == items.count - 1 {
                item.view?.frame = Rect(x: x, y: bounds.minY,
                                        width: bounds.maxX - x, height: bounds.height)
                return bounds.maxX
            } else {
                item.view?.frame = Rect(x: x,
                                        y: bounds.minY,
                                        width: (value.element.minWidth + dx).rounded(),
                                        height: bounds.height)
                return x + item.minWidth + padding
            }
        }
    }
}

final class LayoutView<Value: LayoutValue, Binder: BinderProtocol>
: ModelView, BindableReceiver, Layoutable, Transformable {
    
    typealias Model = Layout<Value>
    typealias BinderKeyPath = ReferenceWritableKeyPath<Binder, Model>
    var binder: Binder {
        didSet { updateWithModel() }
    }
    var keyPath: BinderKeyPath {
        didSet { updateWithModel() }
    }
    var notifications = [((LayoutView<Value, Binder>, BasicPhaseNotification<Model>) -> ())]()
    
    var valueView: View & LayoutMinSize
    
    var viewableType: ViewableType {
        didSet {
            valueView = binder[keyPath: keyPath].value
                .viewWith(binder: binder,
                          keyPath: keyPath.appending(path: \Model.value),
                          type: viewableType)
            updateLayout()
        }
    }
    let knobView = View.discreteKnob()
    
    init(binder: Binder, keyPath: BinderKeyPath, viewableType: ViewableType = .standard) {
        self.binder = binder
        self.keyPath = keyPath
        
        self.viewableType = viewableType
        
        valueView = binder[keyPath: keyPath].value
            .viewWith(binder: binder,
                              keyPath: keyPath.appending(path: \Model.value),
                              type: viewableType)
        
        super.init(isLocked: false)
        children = [valueView, knobView]
        updateWithModel()
    }
    
    let smallHeight = 100.0.cg
    var minSize: Size {
        let knobHeight = bounds.height < smallHeight ?
            Layouter.basicHeight / 2 : Layouter.basicHeight
        return valueView.minSize + Layouter.basicPadding * 2
            + Size(width: 0, height: knobHeight)
    }
    override func updateLayout() {
        let padding = Layouter.basicPadding
        let knobHeight = bounds.height < smallHeight ?
            Layouter.basicHeight / 2 : Layouter.basicHeight
        var b = bounds
        b.size.height -= knobHeight
        b = b.inset(by: padding)
        valueView.frame = b
        knobView.frame = Rect(x: padding, y: b.maxY + padding,
                              width: b.width, height: knobHeight - padding)
    }
    func updateWithModel() {
        transform = model.transform
        let minSize = self.minSize
        bounds = Rect(origin: Point(x: 0, y: -minSize.height), size: minSize)
    }
    
    var movingOrigin: Point {
        get { return model.transform.translation }
        set {
            binder[keyPath: keyPath].transform.translation = newValue
            self.transform.translation = newValue
        }
    }
    
    var oldFrame = Rect()
    func transform(with affineTransform: AffineTransform) {
        frame = oldFrame.applying(affineTransform)
//        model.transform = 
    }
    func anchorPoint(from p: Point) -> Point {
        let frame = transformedBoundingBox
        var minD = p.distance²(frame.minXminYPoint), anchorPoint = frame.maxXmaxYPoint
        var d = p.distance²(frame.midXminYPoint)
        if d < minD {
            anchorPoint = frame.midXmaxYPoint
            minD = d
        }
        d = p.distance²(frame.maxXminYPoint)
        if d < minD {
            anchorPoint = frame.minXmaxYPoint
            minD = d
        }
        d = p.distance²(frame.minXmidYPoint)
        if d < minD {
            anchorPoint = frame.maxXmidYPoint
            minD = d
        }
        d = p.distance²(frame.maxXmidYPoint)
        if d < minD {
            anchorPoint = frame.minXmidYPoint
            minD = d
        }
        d = p.distance²(frame.minXmaxYPoint)
        if d < minD {
            anchorPoint = frame.maxXminYPoint
            minD = d
        }
        d = p.distance²(frame.midXmaxYPoint)
        if d < minD {
            anchorPoint = frame.midXminYPoint
            minD = d
        }
        d = p.distance²(frame.maxXmaxYPoint)
        if d < minD {
            anchorPoint = frame.minXminYPoint
            minD = d
        }
        return anchorPoint
    }
    
    func captureWillMoveObject(at p: Point, to version: Version) {
        oldFrame = frame
    }
}
