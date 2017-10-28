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

 /*
 ## 0.3.0
 * セル、線を再設計
 * 点の追加、点の削除、点の移動と線の変形、スナップを再設計
 * セルの追加時の線の置き換えを廃止、編集セルを廃止、編集表示を再設計
 * マテリアルのコピーによるバインドを廃止、クリックでマテリアルを選択
 * 線の描画、分割を改善
 * 変形、歪曲の再設計
 * コマンドを整理
 * コピー表示、取り消し表示
 * 傾きスナップ
 X カット単位での読み込み
 X ノード (カメラ付き、EditZ描画)
 X マテリアルアニメーション
 X セル補間選択
 
 X ストローク修正
 
 ## 0.4.0
 X Swift4 (Codable導入)
 
 ## 0.5.0
 X レンダリングエンジン変更（Metal API使用予定、リニアワークフロー導入）
 
 ## 1.0
 X 安定版
 */

//# Issue
//SliderなどのUndo実装
//DelegateをClosureに変更
//カプセル化（SceneEditorDelegate実装など）
//DrawingとGroupのItemのイミュータブル化
//正確なディープコピー
//TimelineEditorなどをリファクタリング
//Union選択（選択の結合を明示的に行う）
//コピーUndo
//パネルにindication表示を付ける
//スクロールの可視性の改善、元の位置までの距離などを表示
//トラックパッドの環境設定を無効化または表示反映
//様々なメディアファイルに対応
//ファイルシステムのモードレス化
//シーケンサー、効果音

import Foundation
import QuartzCore

enum EditQuasimode {
    case none, movePoint, moveVertex, snapPoint, moveZ, move, warp, transform
}

protocol Localizable: class {
    var locale: Locale { get set }
}
protocol Respondable: class, Referenceable {
    weak var parent: Respondable? { get set }
    var children: [Respondable] { get set }
    var dataModel: DataModel? { get set }
    func update(withChildren children: [Respondable])
    func removeFromParent()
    func allChildren(_ handler: (Respondable) -> Void)
    func allParents(handler: (Respondable) -> Void)
    var rootRespondable: Respondable { get }
    func setEditQuasimode(_ editQuasimode: EditQuasimode, with event: Event)
    var editQuasimode: EditQuasimode { get set }
    var cursor: Cursor { get }
    func contains(_ p: CGPoint) -> Bool
    var indication: Bool { get set }
    var undoManager: UndoManager? { get set }
    
    func undo(with event: KeyInputEvent)
    func redo(with event: KeyInputEvent)
    func cut(with event: KeyInputEvent) -> CopyObject
    func copy(with event: KeyInputEvent) -> CopyObject
    func paste(_ copyObject: CopyObject, with event: KeyInputEvent)
    func delete(with event: KeyInputEvent)
    func moveToPrevious(with event: KeyInputEvent)
    func moveToNext(with event: KeyInputEvent)
    func play(with event: KeyInputEvent)
    func pasteMaterial(_ copyObject: CopyObject, with event: KeyInputEvent)
    func pasteCell(_ copyObject: CopyObject, with event: KeyInputEvent)
    func splitColor(with event: KeyInputEvent)
    func splitOtherThanColor(with event: KeyInputEvent)
    func addCellWithLines(with event: KeyInputEvent)
    func addAndClipCellWithLines(with event: KeyInputEvent)
    func lassoDelete(with event: KeyInputEvent)
    func lassoSelect(with event: KeyInputEvent)
    func lassoDeleteSelect(with event: KeyInputEvent)
    func clipCellInSelection(with event: KeyInputEvent)
    func hide(with event: KeyInputEvent)
    func show(with event: KeyInputEvent)
    func minimize(with event: KeyInputEvent)
    func changeToRough(with event: KeyInputEvent)
    func removeRough(with event: KeyInputEvent)
    func swapRough(with event: KeyInputEvent)
    func addPoint(with event: KeyInputEvent)
    func deletePoint(with event: KeyInputEvent)
    func movePoint(with event: DragEvent)
    func moveVertex(with event: DragEvent)
    func snapPoint(with event: DragEvent)
    func moveZ(with event: DragEvent)
    func move(with event: DragEvent)
    func warp(with event: DragEvent)
    func transform(with event: DragEvent)
    func moveCursor(with event: MoveEvent)
    func click(with event: DragEvent)
    func drag(with event: DragEvent)
    func scroll(with event: ScrollEvent)
    func zoom(with event: PinchEvent)
    func rotate(with event: RotateEvent)
    func reset(with event: DoubleTapEvent)
    func lookUp(with event: TapEvent) -> Referenceable
}
extension Respondable {
    var dataModel: DataModel? {
        get {
            return nil
        } set {
            children.forEach { $0.dataModel = newValue }
        }
    }
    func allChildren(_ handler: (Respondable) -> Void) {
        func allChildrenRecursion(_ responder: Respondable, _ handler: (Respondable) -> Void) {
            responder.children.forEach { allChildrenRecursion($0, handler) }
            handler(responder)
        }
        allChildrenRecursion(self, handler)
    }
    func allParents(handler: (Respondable) -> Void) {
        handler(self)
        parent?.allParents(handler: handler)
    }
    var rootRespondable: Respondable {
        return parent?.rootRespondable ?? self
    }
    func update(withChildren children: [Respondable]) {
        children.forEach { $0.parent = self }
        allChildren {
            $0.undoManager = undoManager
            $0.dataModel = dataModel
        }
    }
    func removeFromParent() {
        guard let parent = parent else {
            return
        }
        if let index = parent.children.index(where: { $0 === self }) {
            parent.children.remove(at: index)
        }
        self.parent = nil
    }
    func setEditQuasimode(_ editQuasimode: EditQuasimode, with event: Event) {
    }
    var editQuasimode: EditQuasimode {
        get {
            return .none
        } set {
        }
    }
    var cursor: Cursor {
        return Cursor.arrow
    }
    func contains(_ p: CGPoint) -> Bool {
        return false
    }
    var indication: Bool {
        get {
            return false
        } set {
        }
    }
    var undoManager: UndoManager? {
        get {
            return parent?.undoManager
        } set {
        }
    }
    func undo(with event: KeyInputEvent) {
        undoManager?.undo()
    }
    func redo(with event: KeyInputEvent) {
        undoManager?.redo()
    }
    func cut(with event: KeyInputEvent) -> CopyObject {
        let copyObject = copy(with: event)
        delete(with: event)
        return copyObject
    }
    func copy(with event: KeyInputEvent) -> CopyObject {
        return parent?.copy(with: event) ?? CopyObject()
    }
    func paste(_ copyObject: CopyObject, with event: KeyInputEvent) {
        parent?.paste(copyObject, with: event)
    }
    func delete(with event: KeyInputEvent) {
        parent?.delete(with: event)
    }
    func moveToPrevious(with event: KeyInputEvent) {
        parent?.moveToPrevious(with: event)
    }
    func moveToNext(with event: KeyInputEvent) {
        parent?.moveToNext(with: event)
    }
    func play(with event: KeyInputEvent) {
        parent?.play(with: event)
    }
    func pasteMaterial(_ copyObject: CopyObject, with event: KeyInputEvent) {
        parent?.pasteMaterial(copyObject, with: event)
    }
    func pasteCell(_ copyObject: CopyObject, with event: KeyInputEvent) {
        parent?.pasteCell(copyObject, with: event)
    }
    func splitColor(with event: KeyInputEvent) {
        parent?.splitColor(with: event)
    }
    func splitOtherThanColor(with event: KeyInputEvent) {
        parent?.splitOtherThanColor(with: event)
    }
    func addCellWithLines(with event: KeyInputEvent) {
        parent?.addCellWithLines(with: event)
    }
    func addAndClipCellWithLines(with event: KeyInputEvent) {
        parent?.addAndClipCellWithLines(with: event)
    }
    func lassoDelete(with event: KeyInputEvent) {
        parent?.lassoDelete(with: event)
    }
    func lassoSelect(with event: KeyInputEvent) {
        parent?.lassoSelect(with: event)
    }
    func lassoDeleteSelect(with event: KeyInputEvent) {
        parent?.lassoDeleteSelect(with: event)
    }
    func clipCellInSelection(with event: KeyInputEvent) {
        parent?.clipCellInSelection(with: event)
    }
    func hide(with event: KeyInputEvent) {
        parent?.hide(with: event)
    }
    func show(with event: KeyInputEvent) {
        parent?.show(with: event)
    }
    func minimize(with event: KeyInputEvent) {
        parent?.minimize(with: event)
    }
    func changeToRough(with event: KeyInputEvent) {
        parent?.changeToRough(with: event)
    }
    func removeRough(with event: KeyInputEvent) {
        parent?.removeRough(with: event)
    }
    func swapRough(with event: KeyInputEvent) {
        parent?.swapRough(with: event)
    }
    func addPoint(with event: KeyInputEvent) {
        parent?.addPoint(with: event)
    }
    func deletePoint(with event: KeyInputEvent) {
        parent?.deletePoint(with: event)
    }
    func movePoint(with event: DragEvent) {
        parent?.movePoint(with: event)
    }
    func moveVertex(with event: DragEvent) {
        parent?.moveVertex(with: event)
    }
    func snapPoint(with event: DragEvent) {
        parent?.snapPoint(with: event)
    }
    func moveZ(with event: DragEvent) {
        parent?.moveZ(with: event)
    }
    func move(with event: DragEvent) {
        parent?.move(with: event)
    }
    func warp(with event: DragEvent) {
        parent?.warp(with: event)
    }
    func transform(with event: DragEvent) {
        parent?.transform(with: event)
    }
    func moveCursor(with event: MoveEvent) {
        parent?.moveCursor(with: event)
    }
    func click(with event: DragEvent) {
        parent?.click(with: event)
    }
    func drag(with event: DragEvent) {
        parent?.drag(with: event)
    }
    func scroll(with event: ScrollEvent) {
        parent?.scroll(with: event)
    }
    func zoom(with event: PinchEvent) {
        parent?.zoom(with: event)
    }
    func rotate(with event: RotateEvent) {
        parent?.rotate(with: event)
    }
    func reset(with event: DoubleTapEvent) {
        parent?.reset(with: event)
    }
    func lookUp(with event: TapEvent) -> Referenceable {
        return self
    }
}

protocol LayerRespondable: Respondable {
    var layer: CALayer { get }
    func at(_ point: CGPoint) -> Respondable?
    var frame: CGRect { get set }
    var bounds: CGRect { get set }
    var contentsScale: CGFloat { get set }
    func point(from event: Event) -> CGPoint
    func convert(_ point: CGPoint, from responder: LayerRespondable?) -> CGPoint
    func convert(_ point: CGPoint, to responder: LayerRespondable?) -> CGPoint
}
extension LayerRespondable {
    func update(withChildren children: [Respondable]) {
        CATransaction.disableAnimation {
            children.forEach { $0.parent = self }
            layer.sublayers = children.flatMap { ($0 as? LayerRespondable)?.layer }
            allChildren { $0.undoManager = undoManager }
        }
    }
    func removeFromParent() {
        guard let parent = parent else {
            return
        }
        if let index = parent.children.index(where: { $0 === self }) {
            parent.children.remove(at: index)
        }
        self.parent = nil
        layer.removeFromSuperlayer()
    }
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs === rhs
    }
    
    func at(_ point: CGPoint) -> Respondable? {
        guard !layer.isHidden else {
            return nil
        }
        for child in children.reversed() {
            if let childResponder = child as? LayerRespondable {
                let inPoint = childResponder.layer.convert(point, from: layer)
                if let responder = childResponder.at(inPoint) {
                    return responder
                }
            }
        }
        return contains(point) ? self : nil
    }
    func contains(_ p: CGPoint) -> Bool {
        return !layer.isHidden ? layer.contains(p) : false
    }
    var frame: CGRect {
        get {
            return layer.frame
        } set {
            layer.frame = newValue
        }
    }
    var bounds: CGRect {
        get {
            return layer.bounds
        } set {
            layer.bounds = newValue
        }
    }
    var contentsScale: CGFloat {
        get {
            return layer.contentsScale
        } set {
            layer.contentsScale = newValue
        }
    }
    func point(from event: Event) -> CGPoint {
        return layer.convert(event.location, from: nil)
    }
    func convert(_ point: CGPoint, from responder: LayerRespondable?) -> CGPoint {
        return layer.convert(point, from: responder?.layer)
    }
    func convert(_ point: CGPoint, to responder: LayerRespondable?) -> CGPoint {
        return layer.convert(point, to: responder?.layer)
    }
}
