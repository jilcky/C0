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

struct Layout {
    static let smallPadding = 2.0.cf, basicPadding = 3.0.cf, basicLargePadding = 14.0.cf
    static let basicHeight = Font.default.ceilHeight(withPadding: 1) + basicPadding * 2
    static let smallHeight = Font.small.ceilHeight(withPadding: 1) + smallPadding * 2
    static let valueWidth = 56.cf
    static let valueFrame = CGRect(x: 0, y: basicPadding, width: valueWidth, height: basicHeight)
    
    static func centered(_ layers: [Layer],
                         in bounds: CGRect, paddingWidth: CGFloat = 0) {
        
        let w = layers.reduce(-paddingWidth) { $0 +  $1.frame.width + paddingWidth }
        _ = layers.reduce(floor((bounds.width - w) / 2)) { x, layer in
            layer.frame.origin.x = x
            return x + layer.frame.width + paddingWidth
        }
    }
    static func leftAlignmentWidth(_ layers: [Layer], minX: CGFloat = basicPadding,
                                   paddingWidth: CGFloat = 0) -> CGFloat {
        return layers.reduce(minX) { $0 + $1.frame.width + paddingWidth } - paddingWidth
    }
    static func leftAlignment(_ layers: [Layer], minX: CGFloat = basicPadding,
                              y: CGFloat = 0, paddingWidth: CGFloat = 0) {
        _ = layers.reduce(minX) { x, layer in
            layer.frame.origin = CGPoint(x: x, y: y)
            return x + layer.frame.width + paddingWidth
        }
    }
    static func leftAlignment(_ layers: [Layer], minX: CGFloat = basicPadding,
                              y: CGFloat = 0, height: CGFloat, paddingWidth: CGFloat = 0) -> CGSize {
        let width = layers.reduce(minX) { x, layer in
            layer.frame.origin = CGPoint(x: x, y: y + round((height - layer.frame.height) / 2))
            return x + layer.frame.width + paddingWidth
        }
        return CGSize(width: width, height: height)
    }
    static func topAlignment(_ layers: [Layer],
                             minX: CGFloat = basicPadding, minY: CGFloat = basicPadding,
                             minSize: inout CGSize, padding: CGFloat = Layout.basicPadding) {
        
        let width = layers.reduce(0.0.cf) { max($0, $1.defaultBounds.width) } + padding * 2
        let height = layers.reversed().reduce(minY) { y, layerr in
            layerr.frame = CGRect(x: minX, y: y,
                                  width: width, height: layerr.defaultBounds.height)
            return y + layerr.frame.height
        }
        minSize = CGSize(width: width, height: height - minY)
    }
    static func autoHorizontalAlignment(_ layers: [Layer],
                                        padding: CGFloat = 0, in bounds: CGRect) {
        
        guard !layers.isEmpty else {
            return
        }
        let w = layers.reduce(0.0.cf) { $0 +  $1.defaultBounds.width + padding } - padding
        let dx = (bounds.width - w) / layers.count.cf
        _ = layers.enumerated().reduce(bounds.minX) { x, value in
            if value.offset == layers.count - 1 {
                value.element.frame = CGRect(x: x, y: bounds.minY,
                                             width: bounds.maxX - x, height: bounds.height)
                return bounds.maxX
            } else {
                value.element.frame = CGRect(x: x,
                                             y: bounds.minY,
                                             width: round(value.element.defaultBounds.width + dx),
                                             height: bounds.height)
                return x + value.element.frame.width + padding
            }
        }
    }
}
final class Padding: Layer, Respondable {
    static let name = Localization(english: "Padding", japanese: "パディング")
    override init() {
        super.init()
        self.frame = CGRect(origin: CGPoint(),
                            size: CGSize(width: Layout.basicPadding, height: Layout.basicPadding))
    }
}

extension Data {
    var bytesString: String {
        return ByteCountFormatter().string(fromByteCount: Int64(count))
    }
}

extension URL {
    func isConforms(uti: String) -> Bool {
        if let aUTI = self.uti {
            return UTTypeConformsTo(aUTI as CFString, uti as CFString)
        } else {
            return false
        }
    }
    var uti: String? {
        return (try? resourceValues(forKeys: Set([URLResourceKey.typeIdentifierKey])))?
            .typeIdentifier
    }
    init?(bookmark: Data?) {
        guard let bookmark = bookmark else {
            return nil
        }
        do {
            var bookmarkDataIsStale = false
            guard let url = try URL(resolvingBookmarkData: bookmark,
                                    bookmarkDataIsStale: &bookmarkDataIsStale) else {
                                        return nil
            }
            self = url
        } catch {
            return nil
        }
    }
}
extension URL: Referenceable {
    static var  name: Localization {
        return Localization("URL")
    }
}
extension URL: ViewExpression {
    func view(withBounds bounds: CGRect, isSmall: Bool) -> View {
        let thumbnailView = lastPathComponent.view(withBounds: bounds, isSmall: isSmall)
        return ObjectView(object: self, thumbnailView: thumbnailView, minFrame: bounds,
                          isSmall : isSmall)
    }
}

final class LockTimer {
    private var count = 0
    private(set) var wait = false
    func begin(endDuration: Second, beginHandler: () -> Void,
               waitHandler: () -> Void, endHandler: @escaping () -> Void) {
        if wait {
            waitHandler()
            count += 1
        } else {
            beginHandler()
            wait = true
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + endDuration) {
            if self.count == 0 {
                endHandler()
                self.wait = false
            } else {
                self.count -= 1
            }
        }
    }
    private(set) var inUse = false
    private weak var timer: Timer?
    func begin(interval: Second, repeats: Bool = true,
               tolerance: Second = 0.0, handler: @escaping () -> Void) {
        let time = interval + CFAbsoluteTimeGetCurrent()
        let timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault,
                                                    time, repeats ? interval : 0, 0, 0) { _ in
                                                        handler()
        }
        CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer, .commonModes)
        self.timer = timer
        inUse = true
        self.timer?.tolerance = tolerance
    }
    func stop() {
        inUse = false
        timer?.invalidate()
        timer = nil
    }
}

final class Weak<T: AnyObject> {
    weak var value : T?
    init (value: T) {
        self.value = value
    }
}

final class ObjectView: Layer, Respondable {
    static let name = Localization(english: "Object", japanese: "オブジェクト")
    var instanceDescription: Localization {
        return (object as? Referenceable)?.instanceDescription ?? Localization()
    }
    
    let object: Any
    
    var isSmall: Bool
    let nameLabel: Label, thumbnailView: Layer
    init(object: Any, thumbnailView: Layer?, minFrame: CGRect, thumbnailWidth: CGFloat = 40.0,
         isSmall: Bool = false) {
        self.object = object
        if let reference = object as? Referenceable {
            nameLabel = Label(text: type(of: reference).name, font: isSmall ? .smallBold : .bold)
        } else {
            nameLabel = Label(text: Localization(String(describing: type(of: object))),
                              font: isSmall ? .smallBold : .bold)
        }
        self.thumbnailView = thumbnailView ?? Box()
        self.isSmall = isSmall
        
        super.init()
        let width = max(minFrame.width, nameLabel.frame.width + thumbnailWidth)
        self.frame = CGRect(origin: minFrame.origin,
                            size: CGSize(width: width, height: minFrame.height))
        replace(children: [nameLabel, self.thumbnailView])
        updateLayout()
    }
    
    override var locale: Locale {
        didSet {
            updateLayout()
        }
    }
    
    override var bounds: CGRect {
        didSet {
            updateLayout()
        }
    }
    func updateLayout() {
        let padding = isSmall ? Layout.smallPadding : Layout.basicPadding
        nameLabel.frame.origin = CGPoint(x: padding,
                                         y: bounds.height - nameLabel.frame.height - padding)
        thumbnailView.frame = CGRect(x: nameLabel.frame.maxX + padding,
                                     y: padding,
                                     width: bounds.width - nameLabel.frame.width - padding * 3,
                                     height: bounds.height - padding * 2)
    }
    func copiedObjects(with event: KeyInputEvent) -> [Any]? {
        return [object]
    }
}

final class DiscreteSizeView: Layer, Respondable {
    static let name = CGSize.name
    
    private let wLabel = Label(text: Localization("w:"))
    private let widthView = DiscreteNumberView(frame: Layout.valueFrame,
                                               min: 1, max: 10000, numberInterval: 1)
    private let hLabel = Label(text: Localization("h:"))
    private let heightView = DiscreteNumberView(frame: Layout.valueFrame,
                                                min: 1, max: 10000, numberInterval: 1)
    override init() {
        super.init()
        let size = Layout.leftAlignment([wLabel, widthView, Padding(), hLabel, heightView],
                                        height: Layout.basicHeight + Layout.basicPadding * 2)
        frame.size = CGSize(width: size.width + Layout.basicPadding, height: size.height)
        replace(children: [wLabel, widthView, hLabel, heightView])
        
        widthView.binding = { [unowned self] in self.setSize(with: $0) }
        heightView.binding = { [unowned self] in self.setSize(with: $0) }
    }
    
    var size = CGSize() {
        didSet {
            if size != oldValue {
                widthView.number = size.width
                heightView.number = size.height
            }
        }
    }
    
    var defaultSize = CGSize()
    
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
    
    func copiedObjects(with event: KeyInputEvent) -> [Any]? {
        return [size]
    }
    func paste(_ objects: [Any], with event: KeyInputEvent) -> Bool {
        for object in objects {
            if let size = object as? CGSize {
                guard size != self.size else {
                    continue
                }
                set(size, oldSize: self.size)
                return true
            }
        }
        return false
    }
    func delete(with event: KeyInputEvent) -> Bool {
        let size = defaultSize
        guard size != self.size else {
            return false
        }
        set(size, oldSize: self.size)
        return true
    }
    
    func set(_ size: CGSize, oldSize: CGSize) {
        registeringUndoManager?.registerUndo(withTarget: self) { $0.set(oldSize, oldSize: size) }
        binding?(Binding(view: self, size: size, oldSize: oldSize, type: .begin))
        self.size = size
        binding?(Binding(view: self, size: size, oldSize: oldSize, type: .end))
    }
}

final class PointView: Layer, Respondable {
    static let name = CGPoint.name
    
    var backgroundLayers = [Layer]() {
        didSet {
            replace(children: backgroundLayers + [knob])
        }
    }
    
    let knob = Knob()
    init(frame: CGRect = CGRect()) {
        super.init()
        self.frame = frame
        append(child: knob)
    }
    
    override var bounds: CGRect {
        didSet {
            knob.position = position(from: point)
        }
    }
    
    var isOutOfBounds = false {
        didSet {
            if isOutOfBounds != oldValue {
                knob.fillColor = isOutOfBounds ? .warning : .knob
            }
        }
    }
    var padding = 5.0.cf
    
    var defaultPoint = CGPoint()
    var pointAABB = AABB(minX: 0, maxX: 1, minY: 0, maxY: 1) {
        didSet {
            guard pointAABB.maxX - pointAABB.minX > 0 && pointAABB.maxY - pointAABB.minY > 0 else {
                fatalError("Division by zero")
            }
        }
    }
    var point = CGPoint() {
        didSet {
            isOutOfBounds = !pointAABB.contains(point)
            if point != oldValue {
                knob.position = isOutOfBounds ?
                    position(from: clippedPoint(with: point)) : position(from: point)
            }
        }
    }
    
    func clippedPoint(with point: CGPoint) -> CGPoint {
        return pointAABB.clippedPoint(with: point)
    }
    func point(withPosition position: CGPoint) -> CGPoint {
        let inB = bounds.inset(by: padding)
        let x = pointAABB.width * (position.x - inB.origin.x) / inB.width + pointAABB.minX
        let y = pointAABB.height * (position.y - inB.origin.y) / inB.height + pointAABB.minY
        return CGPoint(x: x, y: y)
    }
    func position(from point: CGPoint) -> CGPoint {
        let inB = bounds.inset(by: padding)
        let x = inB.width * (point.x - pointAABB.minX) / pointAABB.width + inB.origin.x
        let y = inB.height * (point.y - pointAABB.minY) / pointAABB.height + inB.origin.y
        return CGPoint(x: x, y: y)
    }
    
    struct Binding {
        let view: PointView, point: CGPoint, oldPoint: CGPoint, type: Action.SendType
    }
    var binding: ((Binding) -> ())?
    
    var disabledRegisterUndo = false
    
    func copiedObjects(with event: KeyInputEvent) -> [Any]? {
        return [point]
    }
    func paste(_ objects: [Any], with event: KeyInputEvent) -> Bool {
        for object in objects {
            if let point = object as? CGPoint {
                guard point != self.point else {
                    continue
                }
                set(point, oldPoint: self.point)
                return true
            }
        }
        return false
    }
    func delete(with event: KeyInputEvent) -> Bool {
        let point = defaultPoint
        guard point != self.point else {
            return false
        }
        set(point, oldPoint: self.point)
        return true
    }
    
    private var oldPoint = CGPoint()
    func move(with event: DragEvent) -> Bool {
        let p = self.point(from: event)
        switch event.sendType {
        case .begin:
            knob.fillColor = .editing
            oldPoint = point
            binding?(Binding(view: self, point: point, oldPoint: oldPoint, type: .begin))
            point = clippedPoint(with: self.point(withPosition: p))
            binding?(Binding(view: self, point: point, oldPoint: oldPoint, type: .sending))
        case .sending:
            point = clippedPoint(with: self.point(withPosition: p))
            binding?(Binding(view: self, point: point, oldPoint: oldPoint, type: .sending))
        case .end:
            point = clippedPoint(with: self.point(withPosition: p))
            if point != oldPoint {
                registeringUndoManager?.registerUndo(withTarget: self) { [point, oldPoint] in
                    $0.set(oldPoint, oldPoint: point)
                }
            }
            binding?(Binding(view: self, point: point, oldPoint: oldPoint, type: .end))
            knob.fillColor = .knob
        }
        return true
    }
    
    func set(_ point: CGPoint, oldPoint: CGPoint) {
        registeringUndoManager?.registerUndo(withTarget: self) { $0.set(oldPoint, oldPoint: point) }
        binding?(Binding(view: self, point: point, oldPoint: oldPoint, type: .begin))
        self.point = point
        binding?(Binding(view: self, point: point, oldPoint: oldPoint, type: .end))
    }
}

final class Progress: Layer, Respondable {
    static let name = Localization(english: "Progress", japanese: "進捗")
    static let feature = Localization(english: "Stop: Send \"Cut\" action",
                                      japanese: "停止: \"カット\"アクションを送信")
    
    let barLayer = Layer()
    let barBackgroundLayer = Layer()
    
    let label: Label
    
    init(frame: CGRect = CGRect(), backgroundColor: Color = .background,
         name: String = "", type: String = "", state: Localization? = nil) {
        
        self.name = name
        self.type = type
        self.state = state
        label = Label()
        label.frame.origin = CGPoint(x: Layout.basicPadding,
                                     y: round((frame.height - label.frame.height) / 2))
        barLayer.frame = CGRect(x: 0, y: 0, width: 0, height: frame.height)
        barBackgroundLayer.fillColor = .editing
        barLayer.fillColor = .content
        
        super.init()
        self.frame = frame
        isClipped = true
        replace(children: [label, barBackgroundLayer, barLayer])
        updateLayout()
    }
    
    var value = 0.0.cf {
        didSet {
            updateLayout()
        }
    }
    func begin() {
        startDate = Date()
    }
    func end() {}
    var startDate: Date?
    var remainingTime: Double? {
        didSet {
            updateString(with: Locale.current)
        }
    }
    var computationTime = 5.0
    var name = "" {
        didSet {
            updateString(with: locale)
        }
    }
    var type = "" {
        didSet {
            updateString(with: locale)
        }
    }
    var state: Localization? {
        didSet {
            updateString(with: locale)
        }
    }
    
    override var locale: Locale {
        didSet {
            updateLayout()
        }
    }
    
    func updateLayout() {
        let padding = Layout.basicPadding
        barBackgroundLayer.frame = CGRect(x: padding, y: padding - 1,
                                          width: (bounds.width - padding * 2), height: 1)
        barLayer.frame = CGRect(x: padding, y: padding - 1,
                                width: floor((bounds.width - padding * 2) * value), height: 1)
        updateString(with: locale)
    }
    func updateString(with locale: Locale) {
        var string = ""
        if let state = state {
            string += state.string(with: locale)
        } else if let remainingTime = remainingTime {
            let minutes = Int(ceil(remainingTime)) / 60
            let seconds = Int(ceil(remainingTime)) - minutes * 60
            if minutes == 0 {
                let translator = Localization(english: "%@sec left",
                                              japanese: "あと%@秒").string(with: locale)
                string += (string.isEmpty ? "" : " ") + String(format: translator, String(seconds))
            } else {
                let translator = Localization(english: "%@min %@sec left",
                                              japanese: "あと%@分%@秒").string(with: locale)
                string += (string.isEmpty ? "" : " ") + String(format: translator,
                                                               String(minutes), String(seconds))
            }
        }
        label.string = type + "(" + name + "), "
            + string + (string.isEmpty ? "" : ", ") + "\(Int(value * 100)) %"
        label.frame.origin = CGPoint(x: Layout.basicPadding,
                                     y: round((frame.height - label.frame.height) / 2))
    }
    
    var deleteHandler: ((Progress) -> (Bool))?
    weak var operation: Operation?
    func delete(with event: KeyInputEvent) -> Bool {
        if let operation = operation {
            operation.cancel()
        }
        return deleteHandler?(self) ?? false
    }
}

extension CGImage {
    var size: CGSize {
        return CGSize(width: width, height: height)
    }
}
extension CGImage: Referenceable {
    static let name = Localization(english: "Image", japanese: "画像")
}

final class ImageView: Layer, Respondable {
    static let name = CGImage.name
    
    init(image: CGImage? = nil) {
        super.init()
        self.image = image
    }
    init(url: URL?) {
        super.init()
        self.url = url
        if let url = url {
            self.image = ImageView.image(with: url)
        }
    }
    
    var url: URL? {
        didSet {
            if let url = url {
                self.image = ImageView.image(with: url)
            }
        }
    }
    static func image(with url: URL) -> CGImage? {
        guard
            let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
            let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
                return nil
        }
        return image
    }
    func delete(with event: KeyInputEvent) -> Bool {
        removeFromParent()
        return true
    }
    enum DragType {
        case move, resizeMinXMinY, resizeMaxXMinY, resizeMinXMaxY, resizeMaxXMaxY
    }
    var dragType = DragType.move, downPosition = CGPoint(), oldFrame = CGRect()
    var resizeWidth = 10.0.cf, ratio = 1.0.cf
    func move(with event: DragEvent) -> Bool {
        guard let parent = parent else {
            return false
        }
        let p = parent.point(from: event), ip = point(from: event)
        switch event.sendType {
        case .begin:
            if CGRect(x: 0, y: 0, width: resizeWidth, height: resizeWidth).contains(ip) {
                dragType = .resizeMinXMinY
            } else if CGRect(x:  bounds.width - resizeWidth, y: 0,
                             width: resizeWidth, height: resizeWidth).contains(ip) {
                dragType = .resizeMaxXMinY
            } else if CGRect(x: 0, y: bounds.height - resizeWidth,
                             width: resizeWidth, height: resizeWidth).contains(ip) {
                dragType = .resizeMinXMaxY
            } else if CGRect(x: bounds.width - resizeWidth, y: bounds.height - resizeWidth,
                             width: resizeWidth, height: resizeWidth).contains(ip) {
                dragType = .resizeMaxXMaxY
            } else {
                dragType = .move
            }
            downPosition = p
            oldFrame = frame
            ratio = frame.height / frame.width
        case .sending, .end:
            let dp =  p - downPosition
            var frame = self.frame
            switch dragType {
            case .move:
                frame.origin = CGPoint(x: oldFrame.origin.x + dp.x, y: oldFrame.origin.y + dp.y)
            case .resizeMinXMinY:
                frame.origin.x = oldFrame.origin.x + dp.x
                frame.origin.y = oldFrame.origin.y + dp.y
                frame.size.width = oldFrame.width - dp.x
                frame.size.height = frame.size.width * ratio
            case .resizeMaxXMinY:
                frame.origin.y = oldFrame.origin.y + dp.y
                frame.size.width = oldFrame.width + dp.x
                frame.size.height = frame.size.width * ratio
            case .resizeMinXMaxY:
                frame.origin.x = oldFrame.origin.x + dp.x
                frame.size.width = oldFrame.width - dp.x
                frame.size.height = frame.size.width * ratio
            case .resizeMaxXMaxY:
                frame.size.width = oldFrame.width + dp.x
                frame.size.height = frame.size.width * ratio
            }
            self.frame = event.sendType == .end ? frame.integral : frame
        }
        return true
    }
}

final class Drager {
    private var downPosition = CGPoint(), oldFrame = CGRect()
    func drag(with event: DragEvent, _ layer: Layer, in parent: Layer) {
        let p = parent.point(from: event)
        switch event.sendType {
        case .begin:
            downPosition = p
            oldFrame = layer.frame
        case .sending:
            let dp =  p - downPosition
            layer.frame.origin = CGPoint(x: oldFrame.origin.x + dp.x,
                                         y: oldFrame.origin.y + dp.y)
        case .end:
            let dp =  p - downPosition
            layer.frame.origin = CGPoint(x: round(oldFrame.origin.x + dp.x),
                                         y: round(oldFrame.origin.y + dp.y))
        }
    }
}
final class Scroller {
    func scroll(with event: ScrollEvent, layer: Layer) {
        layer.frame.origin += event.scrollDeltaPoint
    }
}

final class Knob: Layer {
    init(radius: CGFloat = 5, lineWidth: CGFloat = 1) {
        super.init()
        fillColor = .knob
        lineColor = .border
        self.lineWidth = lineWidth
        self.radius = radius
    }
    var radius: CGFloat {
        get {
            return min(bounds.width, bounds.height) / 2
        }
        set {
            frame = CGRect(x: position.x - newValue, y: position.y - newValue,
                           width: newValue * 2, height: newValue * 2)
            cornerRadius = newValue
        }
    }
}
final class DiscreteKnob: Layer {
    init(_ size: CGSize = CGSize(width: 5, height: 10), lineWidth: CGFloat = 1) {
        super.init()
        fillColor = .knob
        lineColor = .border
        self.lineWidth = lineWidth
        frame.size = size
    }
}
