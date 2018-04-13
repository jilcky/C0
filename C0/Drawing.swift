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

/**
 # Issue
 - 変更通知またはイミュータブル化またはstruct化
 */
final class Drawing: NSObject, NSCoding {
    var lines: [Line], draftLines: [Line], selectedLineIndexes: [Int]
    
    init(lines: [Line] = [], draftLines: [Line] = [], selectedLineIndexes: [Int] = []) {
        self.lines = lines
        self.draftLines = draftLines
        self.selectedLineIndexes = selectedLineIndexes
    }
    
    private enum CodingKeys: String, CodingKey {
        case lines, draftLines, selectedLineIndexes
    }
    init?(coder: NSCoder) {
        lines = coder.decodeDecodable([Line].self, forKey: CodingKeys.lines.rawValue) ?? []
        draftLines = coder.decodeDecodable([Line].self, forKey: CodingKeys.draftLines.rawValue) ?? []
        selectedLineIndexes = coder.decodeObject(
            forKey: CodingKeys.selectedLineIndexes.rawValue) as? [Int] ?? []
        super.init()
    }
    func encode(with coder: NSCoder) {
        coder.encodeEncodable(lines, forKey: CodingKeys.lines.rawValue)
        coder.encodeEncodable(draftLines, forKey: CodingKeys.draftLines.rawValue)
        coder.encode(selectedLineIndexes, forKey: CodingKeys.selectedLineIndexes.rawValue)
    }
    
    func imageBounds(withLineWidth lineWidth: CGFloat) -> CGRect {
        return Line.imageBounds(with: lines, lineWidth: lineWidth)
            .unionNoEmpty(Line.imageBounds(with: draftLines, lineWidth: lineWidth))
    }
    var isEmpty: Bool {
        return lines.isEmpty && draftLines.isEmpty
    }
    
    func nearestLine(at p: CGPoint) -> Line? {
        var minD² = CGFloat.infinity, minLine: Line?
        lines.forEach {
            let d² = $0.minDistance²(at: p)
            if d² < minD² {
                minD² = d²
                minLine = $0
            }
        }
        return minLine
    }
    func isNearestSelectedLineIndexes(at p: CGPoint) -> Bool {
        guard !selectedLineIndexes.isEmpty else {
            return false
        }
        var minD² = CGFloat.infinity, minIndex = 0
        lines.enumerated().forEach {
            let d² = $0.element.minDistance²(at: p)
            if d² < minD² {
                minD² = d²
                minIndex = $0.offset
            }
        }
        return selectedLineIndexes.contains(minIndex)
    }
    var editLines: [Line] {
        return selectedLineIndexes.isEmpty ? lines : selectedLineIndexes.map { lines[$0] }
    }
    var uneditLines: [Line] {
        guard  !selectedLineIndexes.isEmpty else {
            return []
        }
        return (0 ..< lines.count)
            .filter { !selectedLineIndexes.contains($0) }
            .map { lines[$0] }
    }
    
    func intersects(_ otherLines: [Line]) -> Bool {
        for otherLine in otherLines {
            if lines.contains(where: { $0.equalPoints(otherLine) }) {
                return true
            }
        }
        return false
    }
    
    func drawEdit(lineWidth: CGFloat, lineColor: Color, in ctx: CGContext) {
        drawDraft(lineWidth: lineWidth, lineColor: Color.draft, in: ctx)
        draw(lineWidth: lineWidth, lineColor: lineColor, in: ctx)
        drawSelectedLines(lineWidth: lineWidth + 1.5, lineColor: Color.selected, in: ctx)
    }
    func drawDraft(lineWidth: CGFloat, lineColor: Color, in ctx: CGContext) {
        ctx.setFillColor(lineColor.cgColor)
        draftLines.forEach { $0.draw(size: lineWidth, in: ctx) }
    }
    func draw(lineWidth: CGFloat, lineColor: Color, in ctx: CGContext) {
        ctx.setFillColor(lineColor.cgColor)
        lines.forEach { $0.draw(size: lineWidth, in: ctx) }
    }
    func drawSelectedLines(lineWidth: CGFloat, lineColor: Color, in ctx: CGContext) {
        ctx.setFillColor(lineColor.cgColor)
        selectedLineIndexes.forEach { lines[$0].draw(size: lineWidth, in: ctx) }
    }
}
extension Drawing: Referenceable {
    static let name = Localization(english: "Drawing", japanese: "ドローイング")
}
extension Drawing: ClassCopiable {
    func copied(from copier: Copier) -> Drawing {
        return Drawing(lines: lines, draftLines: draftLines, selectedLineIndexes: selectedLineIndexes)
    }
}
extension Drawing: ViewExpression {
    func view(withBounds bounds: CGRect, sizeType: SizeType) -> View {
        let thumbnailView = DrawLayer()
        thumbnailView.drawBlock = { [unowned self, unowned thumbnailView] ctx in
            self.draw(with: thumbnailView.bounds, in: ctx)
        }
        thumbnailView.bounds = bounds
        return ObjectView(object: self, thumbnailView: thumbnailView, minFrame: bounds,
                          sizeType: sizeType)
    }
    func draw(with bounds: CGRect, in ctx: CGContext) {
        let imageBounds = self.imageBounds(withLineWidth: 1)
        let c = CGAffineTransform.centering(from: imageBounds, to: bounds.inset(by: 5))
        ctx.concatenate(c.affine)
        draw(lineWidth: 0.5 / c.scale, lineColor: Color.strokeLine, in: ctx)
        drawDraft(lineWidth: 0.5 / c.scale, lineColor: Color.draft, in: ctx)
    }
}

/**
 # Issue
 - DraftArray、下書き化などのコマンドを排除
 */
final class DrawingView: View {
    var drawing = Drawing()
    
    var sizeType: SizeType
    private let classNameView: TextView
    
    let linesView = ArrayView<Line>()
    let draftLinesView = ArrayView<Line>()
    
    let changeToDraftView = ClosureView(name: Localization(english: "Change to Draft",
                                                           japanese: "下書き化"))
    let removeDraftView = ClosureView(name: Localization(english: "Remove Draft",
                                                         japanese: "下書きを削除"))
    let exchangeWithDraftView = ClosureView(name: Localization(english: "Exchange with Draft",
                                                               japanese: "下書きと交換"))
    let triangleLinesView = [Line].triangle().view(withBounds: CGRect(), sizeType: .small)
    let squareLinesView = [Line].square().view(withBounds: CGRect(), sizeType: .small)
    let pentagonLinesView = [Line].pentagon().view(withBounds: CGRect(), sizeType: .small)
    let hexagonLinesView = [Line].hexagon().view(withBounds: CGRect(), sizeType: .small)
    let circleLinesView = [Line].circle().view(withBounds: CGRect(), sizeType: .small)
    
    init(sizeType: SizeType = .regular) {
        self.sizeType = sizeType
        classNameView = TextView(text: Drawing.name, font: Font.bold(with: sizeType))
        super.init()
        changeToDraftView.closure = { [unowned self] in self.changeToDraft() }
        removeDraftView.closure = { [unowned self] in self.removeDraft() }
        exchangeWithDraftView.closure = { [unowned self] in self.exchangeWithDraft() }
        replace(children: [classNameView,
                           linesView, draftLinesView,
                           changeToDraftView, removeDraftView, exchangeWithDraftView,
                           squareLinesView])
    }
    
    override var defaultBounds: CGRect {
        let padding = Layout.padding(with: sizeType), buttonH = Layout.height(with: sizeType)
        return CGRect(x: 0, y: 0, width: 100,
                      height: classNameView.frame.height + buttonH * 4 + padding * 3)
    }
    override var bounds: CGRect {
        didSet {
            updateLayout()
        }
    }
    private func updateLayout() {
        let padding = Layout.padding(with: sizeType), buttonH = Layout.height(with: sizeType)
        let px = padding, pw = bounds.width - padding * 2
        var py = bounds.height - padding
        py -= classNameView.frame.height
        classNameView.frame.origin = CGPoint(x: padding, y: py)
        py -= padding
        py -= buttonH
        changeToDraftView.frame = CGRect(x: px, y: py, width: pw, height: buttonH)
        py -= buttonH
        removeDraftView.frame = CGRect(x: px, y: py, width: pw, height: buttonH)
        py -= buttonH
        exchangeWithDraftView.frame = CGRect(x: px, y: py, width: pw, height: buttonH)
        py -= buttonH
        squareLinesView.frame = CGRect(x: px, y: py, width: pw, height: buttonH)
    }
    
    var disabledRegisterUndo = true
    
    struct Binding {
        let view: DrawingView
        let drawing: Drawing, oldDrawing: Drawing, type: Action.SendType
    }
    var binding: ((Binding) -> ())?
    
    func changeToDraft() {
        
    }
    func removeDraft() {
        
    }
    func exchangeWithDraft() {
        
    }
    
    func copiedObjects(with event: KeyInputEvent) -> [ViewExpression]? {
        return [drawing.copied]
    }
    func paste(_ objects: [Any], with event: KeyInputEvent) -> Bool {
        for object in objects {
            if let drawing = object as? Drawing {
                if drawing != self.drawing {
                    set(drawing.copied, old: self.drawing)
                    return true
                }
            }
        }
        return false
    }
    func delete(with event: KeyInputEvent) -> Bool {
        let drawing = Drawing()
        guard !self.drawing.isEmpty else {
            return false
        }
        set(drawing, old: self.drawing)
        return true
    }
    
    private func set(_ drawing: Drawing, old oldDrawing: Drawing) {
        registeringUndoManager?.registerUndo(withTarget: self) {
            $0.set(oldDrawing, old: drawing)
        }
        binding?(Binding(view: self, drawing: oldDrawing, oldDrawing: oldDrawing, type: .begin))
        self.drawing = drawing
        binding?(Binding(view: self, drawing: drawing, oldDrawing: oldDrawing, type: .end))
    }
    
    func reference(with event: TapEvent) -> Reference? {
        return drawing.reference
    }
}
