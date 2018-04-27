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

struct Quasimode {
    var modifierEventableTypes: [EventableType], eventableTypes: [EventableType]
    init(modifier modifierEventableTypes: [EventableType] = [], _ eventableTypes: [EventableType]) {
        self.modifierEventableTypes = modifierEventableTypes
        self.eventableTypes = eventableTypes
    }
    
    var allEventableTypes: [EventableType] {
        return modifierEventableTypes + eventableTypes
    }
    
    var displayText: Text {
        let ets = allEventableTypes
        return ets.reduce(into: Text()) { $0 += $0.isEmpty ? $1.name : " " + $1.name }
    }
}
extension Quasimode: DeepCopiable {
}
extension Quasimode: Referenceable {
    static let name = Text(english: "Quasimode", japanese: "擬似モード")
}
extension Quasimode: ObjectViewExpression {
    func thumbnail(withBounds bounds: Rect, _ sizeType: SizeType) -> View {
        return displayText.thumbnail(withBounds: bounds, sizeType)
    }
}

enum Phase {
    case began, changed, ended
}

protocol Eventable {
    var rootLocation: Point { get }
    var time: Second { get }
    var phase: Phase { get }
}
protocol EventableType {
    var name: Text { get }
}
protocol Editor {
    associatedtype EventType: EventableType
    associatedtype Event: Eventable
    var type: EventType { get }
    var event: Event { get }
//    var isUpdate: Bool { get set }
}
struct Inputter: Editor {
    var type: EventType, event: Event//, isUpdate = true
    
    init(type: EventType, event: Event) {
        self.type = type
        self.event = event
    }
    
    struct EventType: EventableType, Equatable {
        static let click = EventType(name: Text(english: "Click", japanese: "クリック"))
        static let subClick = EventType(name: Text(english: "Sub Click", japanese: "副クリック"))
        static let tap = EventType(name: Text(english: "Tap", japanese: "タップ"))
        static let a = EventType(name: "A"), b = EventType(name: "B"), c = EventType(name: "C")
        static let d = EventType(name: "D"), e = EventType(name: "E"), f = EventType(name: "F")
        static let g = EventType(name: "G"), h = EventType(name: "H"), i = EventType(name: "I")
        static let j = EventType(name: "J"), k = EventType(name: "K"), l = EventType(name: "L")
        static let m = EventType(name: "M"), n = EventType(name: "N"), o = EventType(name: "O")
        static let p = EventType(name: "P"), q = EventType(name: "Q"), r = EventType(name: "R")
        static let s = EventType(name: "S"), t = EventType(name: "T"), u = EventType(name: "U")
        static let v = EventType(name: "V"), w = EventType(name: "W"), x = EventType(name: "X")
        static let y = EventType(name: "Y"), z = EventType(name: "Z")
        static let no0 = EventType(name: "0"), no1 = EventType(name: "1"), no2 = EventType(name: "2")
        static let no3 = EventType(name: "3"), no4 = EventType(name: "4"), no5 = EventType(name: "5")
        static let no6 = EventType(name: "6"), no7 = EventType(name: "7"), no8 = EventType(name: "8")
        static let no9 = EventType(name: "9")
        static let minus = EventType(name: "-"), equals = EventType(name: "=")
        static let leftBracket = EventType(name: "["), rightBracket = EventType(name: "]")
        static let backslash = EventType(name: "/"), frontslash = EventType(name: "\\")
        static let apostrophe = EventType(name: "`"), backApostrophe = EventType(name: "^")
        static let comma = EventType(name: ","), period = EventType(name: ".")
        static let semicolon = EventType(name: ";")
        static let space = EventType(name: "space"), `return` = EventType(name: "return")
        static let tab = EventType(name: "tab"), delete = EventType(name: "delete")
        static let escape = EventType(name: "esc")
        static let command = EventType(name: "command"), shift = EventType(name: "shift")
        static let option = EventType(name: "option"), control = EventType(name: "control")
        static let up = EventType(name: "↑"), down = EventType(name: "↓")
        static let left = EventType(name: "←"), right = EventType(name: "→")
        
        var name: Text
    }
    struct Event: Eventable {
        let rootLocation: Point, time: Second, pressure: Real, phase: Phase
    }
}
struct Dragger: Editor {
    var type: EventType, event: Event//, isUpdate = true
    
    init(type: EventType, event: Event) {
        self.type = type
        self.event = event
    }
    
    struct EventType: EventableType, Equatable {
        static let pointing = EventType(name: Text(english: "Pointing", japanese: "ポインティング"))
        static let drag = EventType(name: Text(english: "Drag", japanese: "ドラッグ"))
        static let subDrag = EventType(name: Text(english: "Sub Drag", japanese: "副ドラッグ"))
        
        var name: Text
    }
    struct Event: Eventable {
        var rootLocation: Point, time: Second, pressure: Real, phase: Phase
    }
}
struct Scroller: Editor {
    var type: EventType, event: Event//, isUpdate = true
    
    init(type: EventType, event: Event) {
        self.type = type
        self.event = event
    }
    
    struct EventType: EventableType, Equatable {
        static let scroll = EventType(name: Text(english: "Scroll", japanese: "スクロール"))
        static let upperScroll = EventType(name: Text(english: "Upper Scroll",
                                                      japanese: "上部スクロール"))
        
        var name: Text
    }
    struct Event: Eventable {
        var rootLocation: Point, time: Second, scrollDeltaPoint: Point
        var phase: Phase, momentumPhase: Phase?
    }
}
struct Pincher: Editor {
    var type: EventType, event: Event//, isUpdate = true
    
    init(type: EventType, event: Event) {
        self.type = type
        self.event = event
    }
    
    struct EventType: EventableType, Equatable {
        static let pinch = EventType(name: Text(english: "Pinch", japanese: "ピンチ"))
        
        var name: Text
    }
    struct Event: Eventable {
        var rootLocation: Point, time: Second, magnification: Real, phase: Phase
    }
}
struct Rotater: Editor {
    var type: EventType, event: Event//, isUpdate = true
    
    init(type: EventType, event: Event) {
        self.type = type
        self.event = event
    }
    
    struct EventType: EventableType, Equatable {
        static let rotate = EventType(name: Text(english: "Rotate", japanese: "回転"))
        
        var name: Text
    }
    struct Event: Eventable {
        var rootLocation: Point, time: Second, rotationQuantity: Real, phase: Phase
    }
}

struct Action {
    var name: Text, description: Text, quasimode: Quasimode
    
    init(name: Text = "", description: Text = "", quasimode: Quasimode) {
        self.name = name
        self.description = description
        self.quasimode = quasimode
    }
    
    func isSubset(of other: Action) -> Bool {
        let types = quasimode.allEventableTypes
        let otherTypes = other.quasimode.allEventableTypes
        for type in types {
            if !otherTypes.contains(where: { $0.name == type.name }) {
                return false
            }
        }
        return true
    }
}
extension Action: Equatable {
    static func ==(lhs: Action, rhs: Action) -> Bool {
        return lhs.name == rhs.name
    }
}
extension Action: Referenceable {
    static let name = Text(english: "Action", japanese: "アクション")
}
extension Action: ObjectViewExpression {
    func thumbnail(withBounds bounds: Rect, _ sizeType: SizeType) -> View {
        return name.thumbnail(withBounds: bounds, sizeType)
    }
}

struct ActionEvent {
    var action: Action, phase: Phase//, isUpdate: Bool
    
    func contains(_ other: Action) -> Bool {
        return action == other// && isUpdate
    }
    func isSendable<T: Eventable>(_ event: T) -> Bool {
        return (phase == .began && event.phase == .began) || phase != .began
    }
}
extension ActionEvent: Equatable {
    static func ==(lhs: ActionEvent, rhs: ActionEvent) -> Bool {
        return lhs.action == rhs.action
    }
}

struct EventMap {
    var inputters = [Inputter]()
    var draggers = [Dragger]()
    var scrollers = [Scroller]()
    var pinchers = [Pincher]()
    var rotaters = [Rotater]()
    
    var actionEvents = [ActionEvent]()
    var editedEventableTypes = [EventableType]()
    
    var eventableTypes: [EventableType] {
        return inputters.map { $0.type } as [EventableType]
            + draggers.map { $0.type } as [EventableType]
            + scrollers.map { $0.type } as [EventableType]
            + pinchers.map { $0.type } as [EventableType]
            + rotaters.map { $0.type } as [EventableType]
    }

//    mutating func set(isUpdate: Bool) {
//        (0..<inputters.count).forEach { inputters[$0].isUpdate = isUpdate }
//        (0..<draggers.count).forEach { draggers[$0].isUpdate = isUpdate }
//        (0..<scrollers.count).forEach { scrollers[$0].isUpdate = isUpdate }
//        (0..<pinchers.count).forEach { pinchers[$0].isUpdate = isUpdate }
//        (0..<rotaters.count).forEach { rotaters[$0].isUpdate = isUpdate }
//    }
    
    mutating func updateActionEvents(with actions: [Action]) {
        let lhs = Set(eventableTypes.map { $0.name.currentString })
        let hitActions = actions.filter { action in
            let rhs = Set(action.quasimode.allEventableTypes.map { $0.name.currentString })
            return rhs.isSubset(of: lhs)
        }
        let newActions: [Action] = hitActions.compactMap { action0 in
            for action1 in hitActions {
                guard action0 != action1 else {
                    continue
                }
                if action0.isSubset(of: action1) {
                    return nil
                }
            }
            return action0
        }
        
        let oldActionEvents = actionEvents
        var newActionEvents = [ActionEvent]()
        oldActionEvents.forEach { oldActionEvent in
            if !newActions.contains(where: { $0 == oldActionEvent.action }) {
                newActionEvents.append(ActionEvent(action: oldActionEvent.action, phase: .ended))
            }
        }
        newActionEvents += newActions.map { action in
            let phase: Phase = oldActionEvents.contains(where: { $0.action == action }) ?
                self.phase(with: action) : .began
            return ActionEvent(action: action, phase: phase)
        }
        
        actionEvents = newActionEvents
//        print(draggers.map { $0.event.phase }, "N", newActionEvents.map { $0.phase })
    }
    mutating func removeEndedActionEvent() {
        actionEvents = actionEvents.filter { $0.phase != .ended }
    }
    func phase(with action: Action) -> Phase {
        var isChanged = false
        func phaseWith<T: Editor>(_ editors: [T], _ eventType: T.EventType) -> Phase? {
            for editor in editors {
                if editor.type.name == eventType.name {
                    return editor.event.phase
                }
            }
            return nil
        }
        for eventType in action.quasimode.allEventableTypes {
            if let inputterType = eventType as? Inputter.EventType {
                guard let phase = phaseWith(inputters, inputterType) else {
                    return .ended
                }
                if phase == .ended {
                    return phase
                }
            } else if let draggerType = eventType as? Dragger.EventType {
                guard let phase = phaseWith(draggers, draggerType) else {
                    return .ended
                }
                if phase != .changed {
                    return phase
                }
            } else if let scrollerType = eventType as? Scroller.EventType {
                guard let phase = phaseWith(scrollers, scrollerType) else {
                    return .ended
                }
                if phase != .changed {
                    return phase
                }
            } else if let pincherType = eventType as? Pincher.EventType {
                guard let phase = phaseWith(pinchers, pincherType) else {
                    return .ended
                }
                if phase != .changed {
                    return phase
                }
            } else if let rotaterType = eventType as? Rotater.EventType {
                guard let phase = phaseWith(rotaters, rotaterType) else {
                    return .ended
                }
                if phase != .changed {
                    return phase
                }
            } else {
                return .ended
            }
        }
        return .changed
    }
    
    func containsWithEditedEventableTypes(_ action: Action) -> Bool {
        let allEventableTypes = action.quasimode.allEventableTypes
        for editedEventableType in editedEventableTypes {
            if allEventableTypes.contains(where: { $0.name == editedEventableType.name }) {
                return true
            }
        }
        return false
    }
    func sendableActionEvent(with action: Action) -> ActionEvent? {
        guard containsWithEditedEventableTypes(action) else {
            return nil
        }
        for actionEvent in actionEvents {
            if actionEvent.contains(action) {
                return actionEvent
            }
        }
        return nil
    }
    func sendableActionEvents(with actions: [Action]) -> [ActionEvent] {
        return actions.compactMap { sendableActionEvent(with: $0) }
    }
    func sendableActionEventTuple(with actions: [Action]
        ) -> (main: ActionEvent?, subs: [ActionEvent]) {
        
        let sendableActionEvents = self.sendableActionEvents(with: actions)
        if sendableActionEvents.isEmpty {
            return (nil, [])
        } else if sendableActionEvents.count == 1 {
            return (sendableActionEvents[0], [])
        } else {
            for (i, actionEvent) in sendableActionEvents.enumerated() {
                if actionEvent.phase == .began {
                    return (actionEvent, sendableActionEvents.withRemoved(at: i))
                }
            }
            return (nil, [])
        }
    }
    
    func sendableInputterEvent(with action: Action,
                               _ eventType: Inputter.EventType) -> Inputter.Event? {
        if let actionEvent = sendableActionEvent(with: action),
            let inputterEvent = event(with: eventType),
            actionEvent.isSendable(inputterEvent) && actionEvent.phase == .began {
            
            return inputterEvent
        }
        return nil
    }
    func sendableTuple(with action: Action,
                       _ eventType: Inputter.EventType) -> (Inputter.Event, Phase)? {
        if let actionEvent = sendableActionEvent(with: action),
            let inputterEvent = event(with: eventType),
            actionEvent.isSendable(inputterEvent) {
            
            return (inputterEvent, actionEvent.phase)
        }
        return nil
    }
    func sendableTuple(with actions: [Action], _ eventType: Dragger.EventType
        ) -> (draggerEvent: Dragger.Event, phase: Phase, mainActionEvent: ActionEvent)? {
        
        let selectActionEventTuple = sendableActionEventTuple(with: actions)
        if let main = selectActionEventTuple.main, let draggerEvent = event(with: eventType) {
            if selectActionEventTuple.subs.isEmpty ? main.isSendable(draggerEvent) : true {
                let phase = selectActionEventTuple.subs.isEmpty ? main.phase : .changed
                return (draggerEvent, phase, main)
            } else {
                return nil
            }
        }
        return nil
    }
    func sendableTuple(with action: Action,
                              _ eventType: Dragger.EventType) -> (Dragger.Event, Phase)? {
        if let actionEvent = sendableActionEvent(with: action),
            let draggerEvent = event(with: eventType),
            actionEvent.isSendable(draggerEvent) {
            
            return (draggerEvent, actionEvent.phase)
        }
        return nil
    }
    func sendableScrollerEvent(with action: Action,
                               _ eventType: Scroller.EventType) -> (Scroller.Event, Phase)? {
        if let actionEvent = sendableActionEvent(with: action),
            let scrollerEvent = event(with: eventType),
            actionEvent.isSendable(scrollerEvent) {
            
            return (scrollerEvent, actionEvent.phase)
        }
        return nil
    }
    func sendableTuple(with action: Action,
                               _ eventType: Pincher.EventType) -> (Pincher.Event, Phase)? {
        if let actionEvent = sendableActionEvent(with: action),
            let pincherEvent = event(with: eventType),
            actionEvent.isSendable(pincherEvent) {
            
            return (pincherEvent, actionEvent.phase)
        }
        return nil
    }
    func sendableTuple(with action: Action,
                              _ eventType: Rotater.EventType) -> (Rotater.Event, Phase)? {
        if let actionEvent = sendableActionEvent(with: action),
            let rotaterEvent = event(with: eventType),
            actionEvent.isSendable(rotaterEvent) {
            
            return (rotaterEvent, actionEvent.phase)
        }
        return nil
    }
    
    func event(with type: Inputter.EventType) -> Inputter.Event? {
        for inputter in inputters {
            if inputter.type == type {
                return inputter.event
            }
        }
        return nil
    }
    func event(with type: Dragger.EventType) -> Dragger.Event? {
        for dragger in draggers {
            if dragger.type == type {
                return dragger.event
            }
        }
        return nil
    }
    func event(with type: Scroller.EventType) -> Scroller.Event? {
        for scroller in scrollers {
            if scroller.type == type {
                return scroller.event
            }
        }
        return nil
    }
    func event(with type: Pincher.EventType) -> Pincher.Event? {
        for pincher in pinchers {
            if pincher.type == type {
                return pincher.event
            }
        }
        return nil
    }
    func event(with type: Rotater.EventType) -> Rotater.Event? {
        for rotater in rotaters {
            if rotater.type == type {
                return rotater.event
            }
        }
        return nil
    }
}

/**
 Issue: コピー・ペーストなどのアクション対応を拡大
 Issue: プロトコルアクション設計を拡大
 */
protocol ActionManagable {
    var actions: [Action] { get }
    func send(_ eventMap: EventMap, in rootView: View)
}

enum ViewQuasimode {
    case none, moveZ, transform, warp, editPoint, vertex
}

protocol Indicatable {
    func indicate(at p: Point)
}
final class IndicatableActionManager: ActionManagable {
    typealias Receiver = View & Indicatable
    
    var indicateAction = Action(name: Text(english: "Indicate", japanese: "指し示す"),
                                quasimode: Quasimode([Dragger.EventType.pointing]))
    var actions: [Action] {
        return [indicateAction]
    }
    
    func updateIndicatedView(with frame: Rect, in rootView: View) {
        if frame.contains(self.currentRootLocation) {
            self.indicatedView = rootView.at(self.currentRootLocation)
            if let receiver = self.indicatedView?.withSelfAndAllParents(with: Receiver.self) {
                let p = receiver.convertFromRoot(self.currentRootLocation)
                receiver.indicate(at: p)
            }
        }
    }
    
    var currentRootLocation = Point()
    var indicatedViewBinding: (((indicatedView: View?, oldIndicatedView: View?)) -> ())?
    var indicatedView: View? {
        didSet {
            var allParents = [View]()
            indicatedView?.allSubIndicatedParentsAndSelf { allParents.append($0) }
            oldValue?.allSubIndicatedParentsAndSelf { view in
                if let index = allParents.index(where: { $0 === view }) {
                    allParents.remove(at: index)
                } else {
                    view.isSubIndicated = false
                }
            }
            allParents.forEach { $0.isSubIndicated = true }
            
            oldValue?.isIndicated = false
            indicatedView?.isIndicated = true
            
            indicatedViewBinding?((indicatedView, oldValue))
        }
    }
    
    func send(_ eventMap: EventMap, in rootView: View) {
        if eventMap.sendableActionEvent(with: indicateAction) != nil,
            let dragEvent = eventMap.event(with: .pointing) {
            
            currentRootLocation = dragEvent.rootLocation
            indicatedView = rootView.at(dragEvent.rootLocation)
            
            if let receiver = indicatedView?.withSelfAndAllParents(with: Receiver.self) {
                let p = receiver.convertFromRoot(dragEvent.rootLocation)
                receiver.indicate(at: p)
            }
        }
    }
}

protocol Selectable {
    func select(from rect: Rect, _ phase: Phase)
    func deselect(from rect: Rect, _ phase: Phase)
    func selectAll()
    func deselectAll()
}
final class SelectableActionManager: ActionManagable {
    typealias Receiver = View & Selectable
    
    var selectAction = Action(name: Text(english: "Select", japanese: "選択"),
                              quasimode: Quasimode(modifier: [Inputter.EventType.command],
                                                   [Dragger.EventType.drag]))
    var selectAllAction = Action(name: Text(english: "Select All", japanese: "すべて選択"),
                                 quasimode: Quasimode(modifier: [Inputter.EventType.command],
                                                      [Inputter.EventType.a]))
    var deselectAction = Action(name: Text(english: "Deselect", japanese: "選択解除"),
                                quasimode: Quasimode(modifier: [Inputter.EventType.shift,
                                                                Inputter.EventType.command],
                                                     [Dragger.EventType.drag]))
    var deselectAllAction = Action(name: Text(english: "Deselect All", japanese: "すべて選択解除"),
                                   quasimode: Quasimode(modifier: [Inputter.EventType.shift,
                                                                   Inputter.EventType.command],
                                                        [Inputter.EventType.a]))
    var actions: [Action] {
        return [selectAction, selectAllAction, deselectAction, deselectAllAction]
    }
    
    private final class Selector {
        var selectionView: View?
        weak var receiver: Receiver?
        private var startPoint = Point(), startRootPoint = Point(), oldIsDeselect = false
        func send(_ event: Dragger.Event, _ phase: Phase, in rootView: View, isDeselect: Bool) {
            switch phase {
            case .began:
                let selectionView = isDeselect ? View.deselection : View.selection
                rootView.append(child: selectionView)
                selectionView.frame = Rect(origin: event.rootLocation, size: Size())
                self.selectionView = selectionView
                if let receiver = rootView.at(event.rootLocation, Receiver.self) {
                    startRootPoint = event.rootLocation
                    startPoint = receiver.convertFromRoot(event.rootLocation)
                    self.receiver = receiver
                    
                    let rect = Rect(origin: startPoint, size: Size())
                    if isDeselect {
                        receiver.deselect(from: rect, phase)
                    } else {
                        receiver.select(from: rect, phase)
                    }
                    oldIsDeselect = isDeselect
                }
            case .changed, .ended:
                guard let receiver = receiver else {
                    return
                }
                if isDeselect != oldIsDeselect {
                    selectionView?.fillColor = isDeselect ? .deselect : .select
                    selectionView?.lineColor = isDeselect ? .deselectBorder : .selectBorder
                    oldIsDeselect = isDeselect
                }
                let lp = event.rootLocation
                selectionView?.frame = Rect(origin: startRootPoint,
                                              size: Size(width: lp.x - startRootPoint.x,
                                                           height: lp.y - startRootPoint.y))
                let p = receiver.convertFromRoot(event.rootLocation)
                let aabb = AABB(minX: min(startPoint.x, p.x), maxX: max(startPoint.x, p.x),
                                minY: min(startPoint.y, p.y), maxY: max(startPoint.y, p.y))
                let rect = aabb.rect
                if isDeselect {
                    receiver.deselect(from: rect, phase)
                } else {
                    receiver.select(from: rect, phase)
                }
                
                if phase == .ended {
                    selectionView?.removeFromParent()
                    selectionView = nil
                    self.receiver = nil
                }
            }
        }
    }
    private var selector = Selector()
    
    func send(_ eventMap: EventMap, in rootView: View) {
        if let sendableTuple = eventMap.sendableTuple(with: [selectAction, deselectAction], .drag) {
            selector.send(sendableTuple.draggerEvent, sendableTuple.phase, in: rootView,
                          isDeselect: sendableTuple.mainActionEvent.action == deselectAction)
        }
        if let inputterEvent = eventMap.sendableInputterEvent(with: selectAllAction, .a) {
            if let receiver = rootView.at(inputterEvent.rootLocation, Receiver.self) {
                receiver.selectAll()
            }
        }
        if let inputterEvent = eventMap.sendableInputterEvent(with: deselectAllAction, .a) {
            if let receiver = rootView.at(inputterEvent.rootLocation, Receiver.self) {
                receiver.deselectAll()
            }
        }
    }
}

protocol Bindable {
    func bind(for p: Point)
}
final class BindableActionManager: ActionManagable {
    typealias Receiver = View & Bindable
    
    var bindAction = Action(name: Text(english: "Bind", japanese: "バインド"),
                           quasimode: Quasimode([Inputter.EventType.subClick]))
    var actions: [Action] {
        return [bindAction]
    }
    
    func send(_ eventMap: EventMap, in rootView: View) {
        if let inputterEvent = eventMap.sendableInputterEvent(with: bindAction, .subClick) {
            if let receiver = rootView.at(inputterEvent.rootLocation, Receiver.self) {
                let p = receiver.convertFromRoot(inputterEvent.rootLocation)
                receiver.bind(for: p)
            }
        }
    }
}

protocol Scrollable {
    func scroll(for p: Point, time: Second, scrollDeltaPoint: Point,
                phase: Phase, momentumPhase: Phase?)
}
final class ScrollableActionManager: ActionManagable {
    typealias Receiver = View & Scrollable
    
    var scrollAction = Action(name: Text(english: "Scroll", japanese: "スクロール"),
                              quasimode: Quasimode([Scroller.EventType.scroll]))
    var actions: [Action] {
        return [scrollAction]
    }
    
    private final class ScrollEditor {
        weak var receiver: Receiver?
        func send(_ event: Scroller.Event, _ phase: Phase, in rootView: View) {
            if phase == .began {
                if let receiver = rootView.at(event.rootLocation, Receiver.self) {
                    self.receiver = receiver
                }
            }
            guard let receiver = receiver else {
                return
            }
            let p = receiver.convertFromRoot(event.rootLocation)
            receiver.scroll(for: p, time: event.time, scrollDeltaPoint: event.scrollDeltaPoint,
                            phase: phase, momentumPhase: event.momentumPhase)
        }
    }
    private var scrollEditor = ScrollEditor()
    
    func send(_ eventMap: EventMap, in rootView: View) {
        if let (scrollerEvent, phase) = eventMap.sendableScrollerEvent(with: scrollAction, .scroll) {
            scrollEditor.send(scrollerEvent, phase, in: rootView)
        }
    }
}

protocol Zoomable {
    func zoom(for p: Point, time: Second, magnification: Real, _ phase: Phase)
    func resetView(for p: Point)
}
final class ZoomableActionManager: ActionManagable {
    typealias Receiver = View & Zoomable
    
    var zoomAction = Action(name: Text(english: "Zoom", japanese: "ズーム"),
                            quasimode: Quasimode([Pincher.EventType.pinch]))
    var resetViewAction = Action(name: Text(english: "Reset View", japanese: "表示を初期化"),
                                 quasimode: Quasimode(modifier: [Inputter.EventType.command],
                                                      [Inputter.EventType.b]))
    var actions: [Action] {
        return [zoomAction, resetViewAction]
    }
    
    private final class Zoomer {
        weak var receiver: Receiver?
        func send(_ event: Pincher.Event, _ phase: Phase, in rootView: View) {
            if phase == .began {
                if let receiver = rootView.at(event.rootLocation, Receiver.self) {
                    self.receiver = receiver
                }
            }
            guard let receiver = receiver else {
                return
            }
            let p = receiver.convertFromRoot(event.rootLocation)
            receiver.zoom(for: p, time: event.time, magnification: event.magnification, phase)
            if phase == .ended {
                self.receiver = nil
            }
        }
    }
    private var zoomer = Zoomer()
    
    func send(_ eventMap: EventMap, in rootView: View) {
        if let (pincherEvent, phase) = eventMap.sendableTuple(with: zoomAction, .pinch) {
            zoomer.send(pincherEvent, phase, in: rootView)
        }
        if let inputterEvent = eventMap.sendableInputterEvent(with: resetViewAction, .b) {
            if let receiver = rootView.at(inputterEvent.rootLocation, Receiver.self) {
                let p = receiver.convertFromRoot(inputterEvent.rootLocation)
                receiver.resetView(for: p)
            }
        }
    }
}

protocol Rotatable {
    func rotate(for p: Point, time: Second, rotationQuantity: Real, _ phase: Phase)
}
final class RotatableActionManager: ActionManagable {
    typealias Receiver = View & Rotatable
    
    var rotateAction = Action(name: Text(english: "Rotate", japanese: "回転"),
                              quasimode: Quasimode([Rotater.EventType.rotate]))
    var actions: [Action] {
        return [rotateAction]
    }
    
    private final class RotateEditor {
        weak var receiver: Receiver?
        func send(_ event: Rotater.Event, _ phase: Phase, in rootView: View) {
            if phase == .began {
                if let receiver = rootView.at(event.rootLocation, Receiver.self) {
                    self.receiver = receiver
                }
            }
            guard let receiver = receiver else {
                return
            }
            let p = receiver.convertFromRoot(event.rootLocation)
            receiver.rotate(for: p, time: event.time, rotationQuantity: event.rotationQuantity, phase)
            if phase == .ended {
                self.receiver = nil
            }
        }
    }
    private var rotateEditor = RotateEditor()
    
    func send(_ eventMap: EventMap, in rootView: View) {
        if let (rotaterEvent, phase) = eventMap.sendableTuple(with: rotateAction, .rotate) {
            rotateEditor.send(rotaterEvent, phase, in: rootView)
        }
    }
}

protocol Queryable {
    func reference(at p: Point) -> Reference
}
final class QueryableActionManager: ActionManagable {
    typealias Receiver = View & Queryable
    
    var lookUpAction = Action(name: Text(english: "Look Up", japanese: "調べる"),
                           quasimode: Quasimode([Inputter.EventType.tap]))
    var actions: [Action] {
        return [lookUpAction]
    }
    
    func send(_ eventMap: EventMap, in rootView: View) {
        if let inputterEvent = eventMap.sendableInputterEvent(with: lookUpAction, .tap) {
            if let receiver = rootView.at(inputterEvent.rootLocation, Receiver.self) {
                
                let p = receiver.convertFromRoot(inputterEvent.rootLocation)
                receiver.sendToTop(receiver.reference(at: p))
            }
        }
    }
}

protocol Undoable {
    var undoManager: UndoManager? { get }
    var disabledRegisterUndo: Bool { get }
    var registeringUndoManager: UndoManager? { get }
    func undo()
    func redo()
}
extension Undoable {
    var undoManager: UndoManager? {
        return nil
    }
    var disabledRegisterUndo: Bool {
        return false
    }
    var registeringUndoManager: UndoManager? {
        return disabledRegisterUndo ? nil : undoManager
    }
    func undo() {
        registeringUndoManager?.undo()
    }
    func redo() {
        registeringUndoManager?.redo()
    }
}
final class UndoableActionManager: ActionManagable {
    typealias Receiver = View & Undoable
    
    var undoAction = Action(name: Text(english: "Undo", japanese: "取り消す"),
                           quasimode: Quasimode(modifier: [Inputter.EventType.command],
                                                [Inputter.EventType.z]))
    var redoAction = Action(name: Text(english: "Redo", japanese: "やり直す"),
                            quasimode: Quasimode(modifier: [Inputter.EventType.shift,
                                                            Inputter.EventType.command],
                                                 [Inputter.EventType.z]))
    var actions: [Action] {
        return [undoAction, redoAction]
    }
    
    func send(_ eventMap: EventMap, in rootView: View) {
        if let inputterEvent = eventMap.sendableInputterEvent(with: undoAction, .z) {
            if let receiver = rootView.at(inputterEvent.rootLocation, Receiver.self) {
                receiver.undo()
            }
        }
        if let inputterEvent = eventMap.sendableInputterEvent(with: redoAction, .z) {
            if let receiver = rootView.at(inputterEvent.rootLocation, Receiver.self) {
                receiver.redo()
            }
        }
    }
}

protocol Copiable {
    func copiedViewables(at p: Point) -> [Viewable]
    var topCopiedViewables: [Viewable] { get }
}
protocol Assignable: Copiable {
    func delete(for p: Point)
    func paste(_ objects: [Any], for p: Point)
}
final class AssignableActionManager: ActionManagable {
    typealias Receiver = View & Assignable
    typealias CopyReceiver = View & Copiable
    
    var cutAction = Action(name: Text(english: "Cut", japanese: "カット"),
                            quasimode: Quasimode(modifier: [Inputter.EventType.command],
                                                 [Inputter.EventType.x]))
    var copyAction = Action(name: Text(english: "Copy", japanese: "コピー"),
                            quasimode: Quasimode(modifier: [Inputter.EventType.command],
                                                 [Inputter.EventType.c]))
    var pasteAction = Action(name: Text(english: "Paste", japanese: "ペースト"),
                             quasimode: Quasimode(modifier: [Inputter.EventType.command],
                                                  [Inputter.EventType.v]))
    var actions: [Action] {
        return [cutAction, copyAction, pasteAction]
    }
    
    func send(_ eventMap: EventMap, in rootView: View) {
        if let inputterEvent = eventMap.sendableInputterEvent(with: cutAction, .x) {
            if let receiver = rootView.at(inputterEvent.rootLocation, Receiver.self) {
                let p = receiver.convertFromRoot(inputterEvent.rootLocation)
                let copiedViewables = receiver.copiedViewables(at: p)
                if !copiedViewables.isEmpty {
                    receiver.delete(for: p)
                    receiver.sendToTop(copiedViewables: copiedViewables)
                }
            }
        }
        if let inputterEvent = eventMap.sendableInputterEvent(with: copyAction, .c) {
            if let receiver = rootView.at(inputterEvent.rootLocation, CopyReceiver.self) {
                let p = receiver.convertFromRoot(inputterEvent.rootLocation)
                let copiedViewables = receiver.copiedViewables(at: p)
                if !copiedViewables.isEmpty {
                    receiver.sendToTop(copiedViewables: copiedViewables)
                }
            }
        }
        if let inputterEvent = eventMap.sendableInputterEvent(with: pasteAction, .v) {
            if let receiver = rootView.at(inputterEvent.rootLocation, Receiver.self) {
                let p = receiver.convertFromRoot(inputterEvent.rootLocation)
                receiver.paste(receiver.topCopiedViewables, for: p)
            }
        }
    }
}

protocol Newable {
    func new(for p: Point)
}
final class NewableActionManager: ActionManagable {
    typealias Receiver = View & Newable
    
    var newAction = Action(name: Text(english: "New", japanese: "新規"),
                           quasimode: Quasimode(modifier: [Inputter.EventType.command],
                                                [Inputter.EventType.d]))
    var actions: [Action] {
        return [newAction]
    }
    
    func send(_ eventMap: EventMap, in rootView: View) {
        if let inputterEvent = eventMap.sendableInputterEvent(with: newAction, .d) {
            if let receiver = rootView.at(inputterEvent.rootLocation, Receiver.self) {
                let p = receiver.convertFromRoot(inputterEvent.rootLocation)
                receiver.new(for: p)
            }
        }
    }
}

protocol Runnable {
    func run(for p: Point)
}
final class RunnableActionManager: ActionManagable {
    typealias Receiver = View & Runnable
    
    var runAction = Action(name: Text(english: "Run", japanese: "実行"),
                              quasimode: Quasimode([Inputter.EventType.click]))
    var actions: [Action] {
        return [runAction]
    }
    
    func send(_ eventMap: EventMap, in rootView: View) {
        if let inputterEvent = eventMap.sendableInputterEvent(with: runAction, .click) {
            if let receiver = rootView.at(inputterEvent.rootLocation, Receiver.self) {
                let p = receiver.convertFromRoot(inputterEvent.rootLocation)
                receiver.run(for: p)
            }
        }
    }
}

protocol KeyInputtable {
    func insert(_ string: String, for p: Point)
}

protocol Movable {
    func move(for p: Point, pressure: Real, time: Second, _ phase: Phase)
}
protocol Transformable: Movable {
    var viewQuasimode: ViewQuasimode { get set }
    func transform(for p: Point, pressure: Real, time: Second, _ phase: Phase)
    func warp(for p: Point, pressure: Real, time: Second, _ phase: Phase)
    func moveZ(for p: Point, pressure: Real, time: Second, _ phase: Phase)
}
final class TransformableActionManager: ActionManagable {
    typealias Receiver = View & Transformable
    typealias MoveReceiver = View & Movable
    
    var moveAction = Action(name: Text(english: "Move", japanese: "移動"),
                            quasimode: Quasimode([Dragger.EventType.drag]))
    var transformViewQuasimodeAction = Action(name: Text(english: "Show / Hide Transform",
                                                         japanese: "変形の表示／非表示"),
                                              quasimode: Quasimode([Inputter.EventType.option]))
    var transformAction = Action(name: Text(english: "Transform", japanese: "変形"),
                                 quasimode: Quasimode(modifier: [Inputter.EventType.option],
                                                      [Dragger.EventType.drag]))
    var warpViewQuasimodeAction = Action(name: Text(english: "Show / Hide Warp",
                                                    japanese: "歪曲の表示／非表示"),
                                         quasimode: Quasimode([Inputter.EventType.shift,
                                                               Inputter.EventType.option]))
    var warpAction = Action(name: Text(english: "Warp", japanese: "歪曲"),
                            quasimode: Quasimode(modifier: [Inputter.EventType.shift,
                                                            Inputter.EventType.option],
                                                 [Dragger.EventType.drag]))
    var moveZViewQuasimodeAction = Action(name: Text(english: "Show / Hide Move Z",
                                                         japanese: "Z移動の表示／非表示"),
                                              quasimode: Quasimode([Inputter.EventType.control,
                                                                    Inputter.EventType.option]))
    var moveZAction = Action(name: Text(english: "Move Z", japanese: "Z移動"),
                             quasimode: Quasimode(modifier: [Inputter.EventType.control,
                                                             Inputter.EventType.option],
                                                  [Dragger.EventType.drag]))
    var actions: [Action] {
        return [moveAction,
                transformViewQuasimodeAction, transformAction,
                warpViewQuasimodeAction, warpAction,
                moveZViewQuasimodeAction, moveZAction]
    }
    
    private final class Mover {
        weak var receiver: MoveReceiver?
        func send(_ event: Dragger.Event, _ phase: Phase, in rootView: View) {
            if phase == .began {
                if let receiver = rootView.at(event.rootLocation, MoveReceiver.self) {
                    self.receiver = receiver
                }
            }
            guard let receiver = receiver else {
                return
            }
            let p = receiver.convertFromRoot(event.rootLocation)
            receiver.move(for: p, pressure: event.pressure,
                          time: event.time, phase)
            if phase == .ended {
                self.receiver = nil
            }
        }
    }
    private var mover = Mover()
    
    private final class TransformEditor {
        weak var receiver: Receiver?
        func send(_ event: Dragger.Event, _ phase: Phase, in rootView: View) {
            if phase == .began {
                if let receiver = rootView.at(event.rootLocation, Receiver.self) {
                    self.receiver = receiver
                }
            }
            guard let receiver = receiver else {
                return
            }
            let p = receiver.convertFromRoot(event.rootLocation)
            receiver.transform(for: p, pressure: event.pressure, time: event.time, phase)
            if phase == .ended {
                self.receiver = nil
            }
        }
    }
    private var transformEditor = TransformEditor()
    
    private final class WarpEditor {
        weak var receiver: Receiver?
        func send(_ event: Dragger.Event, _ phase: Phase, in rootView: View) {
            if phase == .began {
                if let receiver = rootView.at(event.rootLocation, Receiver.self) {
                    self.receiver = receiver
                }
            }
            guard let receiver = receiver else {
                return
            }
            let p = receiver.convertFromRoot(event.rootLocation)
            receiver.warp(for: p, pressure: event.pressure, time: event.time, phase)
            if phase == .ended {
                self.receiver = nil
            }
        }
    }
    private var warpEditor = WarpEditor()
    
    private final class MoveZEditor {
        weak var receiver: Receiver?
        func send(_ event: Dragger.Event, _ phase: Phase, in rootView: View) {
            if phase == .began {
                if let receiver = rootView.at(event.rootLocation, Receiver.self) {
                    self.receiver = receiver
                }
            }
            guard let receiver = receiver else {
                return
            }
            let p = receiver.convertFromRoot(event.rootLocation)
            receiver.moveZ(for: p, pressure: event.pressure, time: event.time, phase)
            if phase == .ended {
                self.receiver = nil
            }
        }
    }
    private var moveZEditor = MoveZEditor()
    
    func send(_ eventMap: EventMap, in rootView: View) {
        if let (draggerEvent, phase) = eventMap.sendableTuple(with: moveAction, .drag) {
            mover.send(draggerEvent, phase, in: rootView)
        }
        if let (draggerEvent, phase) = eventMap.sendableTuple(with: transformAction, .drag) {
            transformEditor.send(draggerEvent, phase, in: rootView)
        }
        if let (draggerEvent, phase) = eventMap.sendableTuple(with: warpAction, .drag) {
            warpEditor.send(draggerEvent, phase, in: rootView)
        }
        if let (draggerEvent, phase) = eventMap.sendableTuple(with: moveZAction, .drag) {
            moveZEditor.send(draggerEvent, phase, in: rootView)
        }
    }
}

protocol Strokable {
    func stroke(for p: Point, pressure: Real, time: Second, _ phase: Phase)
    func lassoErase(for p: Point, pressure: Real, time: Second, _ phase: Phase)
}
final class StrokableActionManager: ActionManagable {
    typealias Receiver = View & Strokable
    
    var strokeAction = Action(name: Text(english: "Stroke", japanese: "ストローク"),
                              quasimode: Quasimode([Dragger.EventType.subDrag]))
    var lassoEraseAction = Action(name: Text(english: "Lasso Erase", japanese: "囲み消し"),
                                  quasimode: Quasimode(modifier: [Inputter.EventType.shift],
                                                       [Dragger.EventType.subDrag]))
    var actions: [Action] {
        return [strokeAction, lassoEraseAction]
    }
    
    private final class Stroker {
        weak var receiver: Receiver?
        func send(_ event: Dragger.Event, _ phase: Phase, in rootView: View) {
            if phase == .began {
                if let receiver = rootView.at(event.rootLocation, Receiver.self) {
                    self.receiver = receiver
                }
            }
            guard let receiver = receiver else {
                return
            }
            let p = receiver.convertFromRoot(event.rootLocation)
            receiver.stroke(for: p, pressure: event.pressure, time: event.time, phase)
            if phase == .ended {
                self.receiver = nil
            }
        }
    }
    private var stroker = Stroker()
    
    private final class LassoEraser {
        weak var receiver: Receiver?
        func send(_ event: Dragger.Event, _ phase: Phase, in rootView: View) {
            if phase == .began {
                if let receiver = rootView.at(event.rootLocation, Receiver.self) {
                    self.receiver = receiver
                }
            }
            guard let receiver = receiver else {
                return
            }
            let p = receiver.convertFromRoot(event.rootLocation)
            receiver.lassoErase(for: p, pressure: event.pressure, time: event.time, phase)
            if phase == .ended {
                self.receiver = nil
            }
        }
    }
    private var lassoEraser = LassoEraser()
    
    func send(_ eventMap: EventMap, in rootView: View) {
        if let (draggerEvent, phase) = eventMap.sendableTuple(with: strokeAction, .subDrag) {
            stroker.send(draggerEvent, phase, in: rootView)
        }
        if let (draggerEvent, phase) = eventMap.sendableTuple(with: lassoEraseAction, .subDrag) {
            lassoEraser.send(draggerEvent, phase, in: rootView)
        }
    }
}

protocol PointEditable: class {
    var viewQuasimode: ViewQuasimode { get set }
    func insert(_ p: Point)
    func removeNearestPoint(for p: Point)
    func movePoint(for p: Point, pressure: Real, time: Second, _ phase: Phase)
    func moveVertex(for p: Point, pressure: Real, time: Second, _ phase: Phase)
}
final class PointEditableActionManager: ActionManagable {
    typealias Receiver = View & PointEditable
    
    var pointViewQuasimodeAction = Action(name: Text(english: "Show / Hide Point",
                                                     japanese: "編集点の表示／非表示"),
                                          quasimode: Quasimode([Inputter.EventType.control]))
    var removeEditPointAction = Action(name: Text(english: "Remove Edit Point",
                                                  japanese: "編集点を削除"),
                                       quasimode: Quasimode(modifier: [Inputter.EventType.control],
                                                            [Inputter.EventType.x]))
    var insertEditPointAction = Action(name: Text(english: "Insert Edit Point",
                                                  japanese: "編集点を追加"),
                                       quasimode: Quasimode(modifier: [Inputter.EventType.control],
                                                            [Inputter.EventType.d]))
    var moveEditPointAction = Action(name: Text(english: "Move Edit Point", japanese: "編集点を移動"),
                                     quasimode: Quasimode(modifier: [Inputter.EventType.control],
                                                          [Dragger.EventType.drag]))
    var vertexViewQuasimodeAction = Action(name: Text(english: "Show / Hide Vertex",
                                                      japanese: "頂点の表示／非表示"),
                                           quasimode: Quasimode([Inputter.EventType.shift,
                                                                 Inputter.EventType.control]))
    var moveVertexAction = Action(name: Text(english: "Move Vertex", japanese: "頂点を移動"),
                                  quasimode: Quasimode(modifier: [Inputter.EventType.shift,
                                                                  Inputter.EventType.control],
                                                       [Dragger.EventType.drag]))
    var actions: [Action] {
        return [pointViewQuasimodeAction,
                removeEditPointAction, insertEditPointAction,
                moveEditPointAction,
                vertexViewQuasimodeAction, moveVertexAction]
    }
    
    private weak var oldReceiver: Receiver?
    
    private final class MovePointEditor {
        weak var receiver: Receiver?
        func send(_ event: Dragger.Event, _ phase: Phase, in rootView: View) {
            if phase == .began {
                if let receiver = rootView.at(event.rootLocation, Receiver.self) {
                    self.receiver = receiver
                }
            }
            guard let receiver = receiver else {
                return
            }
            let p = receiver.convertFromRoot(event.rootLocation)
            receiver.movePoint(for: p, pressure: event.pressure, time: event.time, phase)
            if phase == .ended {
                self.receiver = nil
            }
        }
    }
    private var movePointEditor = MovePointEditor()
    
    private final class MoveVertexEditor {
        weak var receiver: Receiver?
        func send(_ event: Dragger.Event, _ phase: Phase, in rootView: View) {
            if phase == .began {
                if let receiver = rootView.at(event.rootLocation, Receiver.self) {
                    self.receiver = receiver
                }
            }
            guard let receiver = receiver else {
                return
            }
            let p = receiver.convertFromRoot(event.rootLocation)
            receiver.moveVertex(for: p, pressure: event.pressure, time: event.time, phase)
            if phase == .ended {
                self.receiver = nil
            }
        }
    }
    private var moveVertexEditor = MoveVertexEditor()
    
    func send(_ eventMap: EventMap, in rootView: View) {
        if eventMap.containsWithEditedEventableTypes(pointViewQuasimodeAction),//no
            let (inputterEvent, _) = eventMap.sendableTuple(with: pointViewQuasimodeAction,
                                                            .control) {
            if let receiver = oldReceiver, inputterEvent.phase == .ended {
                receiver.viewQuasimode = .none
                oldReceiver = nil
            } else if inputterEvent.phase == .began,
                let receiver = rootView.at(inputterEvent.rootLocation, Receiver.self) {
                
                receiver.viewQuasimode = .editPoint
                oldReceiver = receiver
            }
        }
        if eventMap.containsWithEditedEventableTypes(vertexViewQuasimodeAction),//no
            let (inputterEvent, _) = eventMap.sendableTuple(with: pointViewQuasimodeAction,
                                                            .control) {
            if let receiver = oldReceiver, inputterEvent.phase == .ended {
                receiver.viewQuasimode = .none
                oldReceiver = nil
            } else if inputterEvent.phase == .began,
                let receiver = rootView.at(inputterEvent.rootLocation, Receiver.self) {
                
                receiver.viewQuasimode = .vertex
                oldReceiver = receiver
            }
        }
        if let inputterEvent = eventMap.sendableInputterEvent(with: removeEditPointAction, .x) {
            if let receiver = rootView.at(inputterEvent.rootLocation, Receiver.self) {
                let p = receiver.convertFromRoot(inputterEvent.rootLocation)
                receiver.removeNearestPoint(for: p)
            }
        }
        if let inputterEvent = eventMap.sendableInputterEvent(with: insertEditPointAction, .d) {
            if let receiver = rootView.at(inputterEvent.rootLocation, Receiver.self) {
                let p = receiver.convertFromRoot(inputterEvent.rootLocation)
                receiver.insert(p)
            }
        }
        if let (draggerEvent, phase)
            = eventMap.sendableTuple(with: moveEditPointAction, .drag) {
            
            movePointEditor.send(draggerEvent, phase, in: rootView)
        }
        if let (draggerEvent, phase)
            = eventMap.sendableTuple(with: moveVertexAction, .drag) {
            
            moveVertexEditor.send(draggerEvent, phase, in: rootView)
        }
    }
}

final class Sender {
    var indicatableActionManager = IndicatableActionManager()
    var selectableActionManager = SelectableActionManager()
    var bindableActionManager = BindableActionManager()
    var scrollableActionManager = ScrollableActionManager()
    var zoomableActionManager = ZoomableActionManager()
    var rotatableActionManager = RotatableActionManager()
    var queryableActionManager = QueryableActionManager()
    var undoableActionManager = UndoableActionManager()
    var assignableActionManager = AssignableActionManager()
    var newableActionManager = NewableActionManager()
    var runnableActionManager = RunnableActionManager()
    var transformableActionManager = TransformableActionManager()
    var strokableActionManager = StrokableActionManager()
    var pointEditableActionManager = PointEditableActionManager()
    
    var actionManagers: [ActionManagable]
    var actions: [Action]
    
    var rootView: View
    var eventMap = EventMap()
    
    init(rootView: View = View()) {
        self.rootView = rootView
        actionManagers = [indicatableActionManager, selectableActionManager, bindableActionManager,
                          scrollableActionManager, zoomableActionManager, rotatableActionManager,
                          runnableActionManager, queryableActionManager, undoableActionManager,
                          assignableActionManager, newableActionManager, runnableActionManager,
                          transformableActionManager, strokableActionManager,
                          pointEditableActionManager]
        actions = actionManagers.flatMap { $0.actions }
    }
    
    func send(_ inputter: Inputter) {
        eventMap.editedEventableTypes = [inputter.type]
        switch inputter.event.phase {
        case .began:
            if let i = eventMap.inputters.index(where: { $0.type == inputter.type }) {
                eventMap.inputters[i] = inputter
            } else {
                eventMap.inputters.append(inputter)
            }
            send()
        case .changed:
            if let i = eventMap.inputters.index(where: { $0.type == inputter.type }) {
                eventMap.inputters[i] = inputter
                send()
            }
        case .ended:
            if let i = eventMap.inputters.index(where: { $0.type == inputter.type }) {
                eventMap.inputters[i] = inputter
                send()
                eventMap.inputters.remove(at: i)
            }
        }
        eventMap.editedEventableTypes = []
    }
    
    func send(_ dragger: Dragger) {
        eventMap.editedEventableTypes = [dragger.type]
        switch dragger.event.phase {
        case .began:
            if let i = eventMap.draggers.index(where: { $0.type == dragger.type }) {
                eventMap.draggers[i] = dragger
            } else {
                eventMap.draggers.append(dragger)
            }
            send()
        case .changed:
            if let i = eventMap.draggers.index(where: { $0.type == dragger.type }) {
                eventMap.draggers[i] = dragger
                send()
            }
        case .ended:
            if let i = eventMap.draggers.index(where: { $0.type == dragger.type }) {
                eventMap.draggers[i] = dragger
                send()
                eventMap.draggers.remove(at: i)
            }
        }
        eventMap.editedEventableTypes = []
    }
    
    func send(_ scroller: Scroller) {
        eventMap.editedEventableTypes = [scroller.type]
        switch scroller.event.phase {
        case .began:
            if let i = eventMap.scrollers.index(where: { $0.type == scroller.type }) {
                eventMap.scrollers[i] = scroller
            } else {
                eventMap.scrollers.append(scroller)
            }
            send()
        case .changed:
            if let i = eventMap.scrollers.index(where: { $0.type == scroller.type }) {
                eventMap.scrollers[i] = scroller
                send()
            }
        case .ended:
            if let i = eventMap.scrollers.index(where: { $0.type == scroller.type }) {
                eventMap.scrollers[i] = scroller
                send()
                eventMap.scrollers.remove(at: i)
            }
        }
        eventMap.editedEventableTypes = []
    }
    
    func send(_ pincher: Pincher) {
        eventMap.editedEventableTypes = [pincher.type]
        switch pincher.event.phase {
        case .began:
            if let i = eventMap.pinchers.index(where: { $0.type == pincher.type }) {
                eventMap.pinchers[i] = pincher
            } else {
                eventMap.pinchers.append(pincher)
            }
            send()
        case .changed:
            if let i = eventMap.pinchers.index(where: { $0.type == pincher.type }) {
                eventMap.pinchers[i] = pincher
                send()
            }
        case .ended:
            if let i = eventMap.pinchers.index(where: { $0.type == pincher.type }) {
                eventMap.pinchers[i] = pincher
                send()
                eventMap.pinchers.remove(at: i)
            }
        }
        eventMap.editedEventableTypes = []
    }
    
    func send(_ rotater: Rotater) {
        eventMap.editedEventableTypes = [rotater.type]
        switch rotater.event.phase {
        case .began:
            if let i = eventMap.rotaters.index(where: { $0.type == rotater.type }) {
                eventMap.rotaters[i] = rotater
            } else {
                eventMap.rotaters.append(rotater)
            }
            send()
        case .changed:
            if let i = eventMap.rotaters.index(where: { $0.type == rotater.type }) {
                eventMap.rotaters[i] = rotater
                send()
            }
        case .ended:
            if let i = eventMap.rotaters.index(where: { $0.type == rotater.type }) {
                eventMap.rotaters[i] = rotater
                send()
                eventMap.rotaters.remove(at: i)
            }
        }
        eventMap.editedEventableTypes = []
    }
    
    func send() {
        eventMap.updateActionEvents(with: actions)
        actionManagers.forEach { $0.send(eventMap, in: rootView) }
        eventMap.removeEndedActionEvent()
    }
}
extension Sender: Referenceable {
    static let name = Text(english: "Sender", japanese: "センダー")
    static let classDescription = Text(english: "Depends on OS preference.",
                                       japanese: "OSの環境設定に依存")
}

final class QuasimodeView: View, Copiable {
    var quasimode: Quasimode {
        didSet {
            textView.text = quasimode.displayText
            if isSizeToFit {
                bounds = defaultBounds
            }
            updateLayout()
        }
    }
    
    var isSizeToFit: Bool
    var textView: TextView
    
    init(quasimode: Quasimode, isSizeToFit: Bool = true) {
        self.quasimode = quasimode
        self.isSizeToFit = isSizeToFit
        textView = TextView(text: quasimode.displayText,
                                font: Font(monospacedSize: 10), frameAlignment: .right)
        
        super.init()
        if isSizeToFit {
            bounds = defaultBounds
        }
        children = [textView]
        updateLayout()
    }
    
    override var locale: Locale {
        didSet {
            if isSizeToFit {
                bounds = defaultBounds
            }
            updateLayout()
        }
    }
    
    override var defaultBounds: Rect {
        return Rect(x: 0, y: 0, width: textView.bounds.width, height: textView.bounds.height)
    }
    override var bounds: Rect {
        didSet {
            updateLayout()
        }
    }
    func updateLayout() {
        textView.frame.origin = Point(x: 0, y: bounds.height - textView.frame.height)
    }
    
    func copiedViewables(at p: Point) -> [Viewable] {
        return [quasimode]
    }
    
    func reference(at p: Point) -> Reference {
        return Quasimode.reference
    }
}

final class ActionView: View, Copiable {
    var action: Action {
        didSet {
            nameView.text = action.name
            quasimodeView.quasimode = action.quasimode
        }
    }
    
    var nameView: TextView, quasimodeView: QuasimodeView
    
    init(action: Action, frame: Rect) {
        self.action = action
        nameView = TextView(text: action.name)
        quasimodeView = QuasimodeView(quasimode: action.quasimode)
        
        super.init()
        self.frame = frame
        children = [nameView, quasimodeView]
    }
    
    func copiedViewables(at p: Point) -> [Viewable] {
        return [action]
    }
    
    override var defaultBounds: Rect {
        let padding = Layout.basicPadding
        let width = nameView.bounds.width + padding + quasimodeView.bounds.width
        let height = nameView.frame.height + Layout.smallPadding * 2
        return Rect(x: 0, y: 0, width: width, height: height)
    }
    override var bounds: Rect {
        didSet {
            updateLayout()
        }
    }
    func updateLayout() {
        let padding = Layout.smallPadding
        nameView.frame.origin = Point(x: padding,
                                        y: bounds.height - nameView.frame.height - padding)
        quasimodeView.frame.origin = Point(x: bounds.width - quasimodeView.frame.width - padding,
                                             y: bounds.height - nameView.frame.height - padding)
    }
    
    func reference(at p: Point) -> Reference {
        return Action.reference
    }
}

final class ActionManagableView: View {
    var actionMangable: ActionManagable
    
    init(actionMangable: ActionManagable) {
        self.actionMangable = actionMangable
        super.init()
        bounds = defaultBounds
    }
    
    static let defaultWidth = 220 + Layout.basicPadding * 2
    
    override var defaultBounds: Rect {
        let padding = Layout.basicPadding
        let actionHeight = Layout.basicTextHeight + Layout.smallPadding * 2
        let height = actionHeight * Real(actionMangable.actions.count) + padding * 2
        return Rect(x: 0, y: 0, width: ActionManagableView.defaultWidth, height: height)
    }
    override var bounds: Rect {
        didSet {
            updateLayout()
        }
    }
    func updateLayout() {
        let padding = Layout.basicPadding
        let actionHeight = Layout.basicTextHeight + Layout.smallPadding * 2
        let aw = bounds.width - padding * 2
        var y = bounds.height - padding
        children = actionMangable.actions.map {
            y -= actionHeight
            let actionView = ActionView(action: $0,
                                        frame: Rect(x: padding, y: y,
                                                      width: aw, height: actionHeight))
            return actionView
        }
    }
}

/**
 Issue: アクションの表示をキーボードに常に表示（ハードウェアの変更が必要）
 Issue: コマンドの編集自由化
 */
final class SenderView: View, Queryable {
    var sender = Sender()
    
    let classNameView = TextView(text: Sender.name, font: .bold)
    var actionManagableViews = [ActionManagableView]()
    
    override init() {
        actionManagableViews = sender.actionManagers.map { ActionManagableView(actionMangable: $0) }
        
        super.init()
        children = [classNameView] + actionManagableViews
        bounds = defaultBounds
    }
    
    override var locale: Locale {
        didSet {
            updateLayout()
        }
    }
    
    override var defaultBounds: Rect {
        let padding = Layout.basicPadding
        let ah = actionManagableViews.reduce(0.0.cg) { $0 + $1.bounds.height }
        let height = classNameView.frame.height + padding * 3 + ah
        return Rect(x: 0, y: 0,
                      width: ActionManagableView.defaultWidth + padding * 2,
                      height: height)
    }
    override var bounds: Rect {
        didSet {
            updateLayout()
        }
    }
    func updateLayout() {
        let padding = Layout.basicPadding
        let w = bounds.width - padding * 2
        var y = bounds.height - classNameView.frame.height - padding
        classNameView.frame.origin = Point(x: padding, y: y)
        y -= padding
        _ = actionManagableViews.reduce(y) {
            let ny = $0 - $1.frame.height
            $1.frame = Rect(x: padding, y: ny, width: w, height: $1.frame.height)
            return ny
        }
    }
    
    func reference(at p: Point) -> Reference {
        return Sender.reference
    }
}
