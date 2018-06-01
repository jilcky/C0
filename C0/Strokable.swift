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

import func CoreGraphics.sqrt

protocol ViewStroker: class {
    var strokableView: View & Strokable { get }
    func stroke(for p: Point, pressure: Real, time: Second, _ phase: Phase)
    func lassoErase(for p: Point, pressure: Real, time: Second, _ phase: Phase)
}

protocol Strokable {
    var viewScale: Real { get }
    func insertWillStorkeObject(at p: Point, to version: Version)
    func captureWillEraseObject(at p: Point, to version: Version)
    func makeViewStroker() -> ViewStroker
}

struct StrokableActionManager: SubActionManagable {
    let strokeAction = Action(name: Text(english: "Stroke", japanese: "ストローク"),
                              quasimode: Quasimode([.drag(.subDrag)]))
    let lassoEraseAction = Action(name: Text(english: "Lasso Erase", japanese: "囲み消し"),
                                  quasimode: Quasimode(modifier: [.input(.shift)],
                                                       [.drag(.subDrag)]))
    var actions: [Action] {
        return [strokeAction, lassoEraseAction]
    }
}
extension StrokableActionManager: SubSendable {
    func makeSubSender() -> SubSender {
        return StrokableSender(actionManager: self)
    }
}

final class StrokableSender: SubSender {
    typealias Receiver = View & Strokable
    
    typealias ActionManager = StrokableActionManager
    var actionManager: ActionManager
    
    init(actionManager: ActionManager) {
        self.actionManager = actionManager
    }
    
    private var viewStroker: ViewStroker?
    
    func send(_ actionMap: ActionMap, from sender: Sender) {
        switch actionMap.action {
        case actionManager.strokeAction:
            if let eventValue = actionMap.eventValuesWith(DragEvent.self).first {
                if actionMap.phase == .began,
                    let receiver = sender.mainIndicatedView as? Receiver {
                    
                    viewStroker = receiver.makeViewStroker()
                    let p = receiver.convertFromRoot(eventValue.rootLocation)
                    receiver.insertWillStorkeObject(at: p, to: sender.indicatedVersionView.version)
                }
                guard let viewStroker = viewStroker else { return }
                let p = viewStroker.strokableView.convertFromRoot(eventValue.rootLocation)
                viewStroker.stroke(for: p, pressure: eventValue.pressure,
                                   time: eventValue.time, actionMap.phase)
                if actionMap.phase == .ended {
                    self.viewStroker = nil
                }
            }
        case actionManager.lassoEraseAction:
            if let eventValue = actionMap.eventValuesWith(DragEvent.self).first {
                if actionMap.phase == .began,
                    let receiver = sender.mainIndicatedView as? Receiver {
                    
                    viewStroker = receiver.makeViewStroker()
                    let p = receiver.convertFromRoot(eventValue.rootLocation)
                    receiver.captureWillEraseObject(at: p, to: sender.indicatedVersionView.version)
                }
                guard let viewStroker = viewStroker else { return }
                let p = viewStroker.strokableView.convertFromRoot(eventValue.rootLocation)
                viewStroker.lassoErase(for: p, pressure: eventValue.pressure,
                                       time: eventValue.time, actionMap.phase)
                if actionMap.phase == .ended {
                    self.viewStroker = nil
                }
            }
        default: break
        }
    }
}

protocol ZoomableStrokable: Strokable {
    var viewScale: Real { get }
    func convertToCurrentLocal(_ point: Point) -> Point
}
final class BasicViewStroker: ViewStroker {
    var view: View & ZoomableStrokable
    var strokableView: View & Strokable {
        return view
    }
    
    init(zoomableSstokableView: View & ZoomableStrokable) {
        self.view = zoomableSstokableView
    }
    
    var line: Line?
    var lineWidth = 1.0.cg, lineColor = Color.strokeLine
    
    struct Temp {
        var control: Line.Control, speed: Real
    }
    var temps = [Temp]()
    var oldPoint = Point(), tempDistance = 0.0.cg, oldLastBounds = Rect.null
    var beginTime = Second(0.0), oldTime = Second(0.0), oldTempTime = Second(0.0)
    
    var join = Join()
    
    struct Join {
        var lowAngle = 0.8.cg * (.pi / 2), angle = 1.5.cg * (.pi / 2)
        
        func joinControlWith(_ line: Line, lastControl lc: Line.Control) -> Line.Control? {
            guard line.controls.count >= 4 else {
                return nil
            }
            let c0 = line.controls[line.controls.count - 4]
            let c1 = line.controls[line.controls.count - 3], c2 = lc
            guard c0.point != c1.point && c1.point != c2.point else {
                return nil
            }
            let dr = abs(Point.differenceAngle(p0: c0.point, p1: c1.point, p2: c2.point))
            if dr > angle {
                return c1
            } else if dr > lowAngle {
                let t = 1 - (dr - lowAngle) / (angle - lowAngle)
                return Line.Control(point: Point.linear(c1.point, c2.point, t: t),
                                    pressure: Real.linear(c1.pressure, c2.pressure, t: t))
            } else {
                return nil
            }
        }
    }
    
    var interval = Interval()
    
    struct Interval {
        var minSpeed = 100.0.cg, maxSpeed = 1500.0.cg, exp = 2.0.cg
        var minTime = Second(0.1), maxTime = Second(0.03)
        var minDistance = 1.45.cg, maxDistance = 1.5.cg
        
        func speedTWith(distance: Real, deltaTime: Second, scale: Real) -> Real {
            let speed = ((distance / scale) / deltaTime).clip(min: minSpeed, max: maxSpeed)
            return ((speed - minSpeed) / (maxSpeed - minSpeed)) ** (1 / exp)
        }
        func isAppendPointWith(distance: Real, deltaTime: Second,
                               _ temps: [Temp], scale: Real) -> Bool {
            guard deltaTime > 0 else {
                return false
            }
            let t = speedTWith(distance: distance, deltaTime: deltaTime, scale: scale)
            let time = minTime + (maxTime - minTime) * t
            return deltaTime > time || isAppendPointWith(temps, scale: scale)
        }
        private func isAppendPointWith(_ temps: [Temp], scale: Real) -> Bool {
            let ap = temps.first!.control.point, bp = temps.last!.control.point
            for tc in temps {
                let speed = tc.speed.clip(min: minSpeed, max: maxSpeed)
                let t = ((speed - minSpeed) / (maxSpeed - minSpeed)) ** (1 / exp)
                let maxD = minDistance + (maxDistance - minDistance) * t
                if tc.control.point.distanceWithLine(ap: ap, bp: bp) > maxD / scale {
                    return true
                }
            }
            return false
        }
    }
    
    var short = Short()
    
    struct Short {
        var minTime = Second(0.1), linearMaxDistance = 1.5.cg
        
        func shortedLineWith(_ line: Line, deltaTime: Second, scale: Real) -> Line {
            guard deltaTime < minTime && line.controls.count > 3 else {
                return line
            }
            
            var maxD = 0.0.cg, maxControl = line.controls[0]
            line.controls.forEach { control in
                let d = control.point.distanceWithLine(ap: line.firstPoint, bp: line.lastPoint)
                if d > maxD {
                    maxD = d
                    maxControl = control
                }
            }
            let mcp = maxControl.point.nearestWithLine(ap: line.firstPoint, bp: line.lastPoint)
            let cp = 2 * maxControl.point - mcp
            let b = Bezier2(p0: line.firstPoint, cp: cp, p1: line.lastPoint)
            
            let linearMaxDistance = self.linearMaxDistance / scale
            var isShorted = true
            for p in line.mainPointSequence {
                let nd = sqrt(b.minDistance²(at: p))
                if nd > linearMaxDistance {
                    isShorted = false
                }
            }
            return isShorted ?
                line :
                Line(controls: [line.controls[0],
                                Line.Control(point: cp, pressure: maxControl.pressure),
                                line.controls[line.controls.count - 1]])
        }
    }
    
    func stroke(for p: Point, pressure: Real, time: Second, _ phase: Phase) {
        stroke(for: p, pressure: pressure, time: time, phase, isAppendLine: true)
    }
    func stroke(for point: Point, pressure: Real, time: Second, _ phase: Phase,
                isAppendLine: Bool) {
        let p = view.convertToCurrentLocal(point)
        switch phase {
        case .began:
            let fc = Line.Control(point: p, pressure: pressure)
            line = Line(controls: [fc, fc, fc])
            oldPoint = p
            oldTime = time
            oldTempTime = time
            tempDistance = 0
            temps = [Temp(control: fc, speed: 0)]
            beginTime = time
        case .changed:
            guard var line = line, p != oldPoint else { return }
            let d = p.distance(oldPoint)
            tempDistance += d
            
            let pressure = (temps.first!.control.pressure + pressure) / 2
            let rc = Line.Control(point: line.controls[line.controls.count - 3].point,
                                  pressure: pressure)
            line.controls[line.controls.count - 3] = rc
            
            let speed = d / (time - oldTime)
            temps.append(Temp(control: Line.Control(point: p, pressure: pressure), speed: speed))
            let lPressure = temps.reduce(0.0.cg) { $0 + $1.control.pressure } / Real(temps.count)
            let lc = Line.Control(point: p, pressure: lPressure)
            
            let mlc = lc.mid(temps[temps.count - 2].control)
            if let jc = join.joinControlWith(line, lastControl: mlc) {
                line.controls[line.controls.count - 2] = jc
                temps = [Temp(control: lc, speed: speed)]
                oldTempTime = time
                tempDistance = 0
            } else if interval.isAppendPointWith(distance: tempDistance / view.viewScale,
                                                 deltaTime: time - oldTempTime,
                                                 temps,
                                                 scale: view.viewScale) {
                line.controls[line.controls.count - 2] = lc
                temps = [Temp(control: lc, speed: speed)]
                oldTempTime = time
                tempDistance = 0
            }
            
            line.controls[line.controls.count - 2] = lc
            line.controls[line.controls.count - 1] = lc
            self.line = line
            
            oldTime = time
            oldPoint = p
        case .ended:
            guard var line = line else { return }
            if !interval.isAppendPointWith(distance: tempDistance / view.viewScale,
                                           deltaTime: time - oldTempTime,
                                           temps,
                                           scale: view.viewScale) {
                line.controls.remove(at: line.controls.count - 2)
            }
            line.controls[line.controls.count - 1]
                = Line.Control(point: p, pressure: line.controls.last!.pressure)
            line = short.shortedLineWith(line, deltaTime: time - beginTime,
                                         scale: view.viewScale)
            self.line = line
        }
    }
    
    var lines = [Line]()
    
    func lassoErase(for p: Point, pressure: Real, time: Second, _ phase: Phase) {
        _ = stroke(for: p, pressure: pressure, time: time, phase, isAppendLine: false)
        switch phase {
        case .began:
            break
        case .changed, .ended:
            if let line = line {
                lassoErase(with: line)
            }
        }
    }
    func lassoErase(with line: Line) {        
        var isRemoveLineInDrawing = false
        let lasso = GeometryLasso(geometry: Geometry(lines: [line]))
        let newDrawingLines = lines.reduce(into: [Line]()) {
            if let splitedLine = lasso.splitedLine(with: $1) {
                switch splitedLine {
                case .around:
                    isRemoveLineInDrawing = true
                case .splited(let lines):
                    isRemoveLineInDrawing = true
                    $0 += lines
                }
            } else {
                $0.append($1)
            }
        }
        if isRemoveLineInDrawing {
            self.lines = newDrawingLines
        }
    }
}