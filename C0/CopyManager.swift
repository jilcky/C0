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

protocol Copying: class {
    var copied: Self { get }
    func copied(from copier: Copier) -> Self
}
extension Copying {
    var copied: Self {
        return Copier().copied(self)
    }
    func copied(from copier: Copier) -> Self {
        return self
    }
}
final class Copier {
    var userInfo = [String: Any]()
    func copied<T: Copying>(_ object: T) -> T {
        let key = String(describing: T.self)
        let oim: ObjectIdentifierManager<T>
        if let o = userInfo[key] as? ObjectIdentifierManager<T> {
            oim = o
        } else {
            oim = ObjectIdentifierManager<T>()
            userInfo[key] = oim
        }
        let objectID = ObjectIdentifier(object)
        if let copyManager = oim.objects[objectID] {
            return copyManager
        } else {
            let copyManager = object.copied(from: self)
            oim.objects[objectID] = copyManager
            return copyManager
        }
    }
}
private final class ObjectIdentifierManager<T> {
    var objects = [ObjectIdentifier: T]()
}

protocol Copiable {
    var copied: Self { get }
}
final class CopyManager {
    var copiedObjects: [Any] {
        didSet {
            copiedObjectsBinding?(copiedObjects)
        }
    }
    var copiedObjectsBinding: (([Any]) -> ())?
    
    init(copiedObjects: [Any] = []) {
        self.copiedObjects = copiedObjects
    }
}
extension CopyManager: Referenceable {
    static let name = Localization(english: "Copy Manager", japanese: "コピー管理")
}
final class CopyManagerView: Layer, Respondable {
    static let name = CopyManager.name
    
    var rootCopyManager = CopyManager() {
        didSet {
            rootCopyManager.copiedObjectsBinding = { [unowned self] in self.didSet(copiedObjects: $0) }
            updateCopiedObjectsView()
        }
    }
    override var copyManager: CopyManager {
        return rootCopyManager
    }
    func didSet(copiedObjects: [Any]) {
        changeCount += 1
        updateCopiedObjectsView()
    }
    var changeCount = 0
    
    var objectViewWidth = 80.0.cf, versionWidth = 120.0.cf
    
    let nameLabel = Label(text: CopyManager.name, font: .bold)
    let versionView = VersionView()
    let copiedLabel = Label(text: Localization(english: "Copied:", japanese: "コピー済み:"))
    let copiedObjectsView = ArrayView<Any>()
    
    override init() {
        versionView.frame = CGRect(x: 0, y: 0, width: versionWidth, height: Layout.basicHeight)
        versionView.rootUndoManager = rootUndoManager
        
        super.init()
        rootCopyManager.copiedObjectsBinding = { [unowned self] in self.didSet(copiedObjects: $0) }
        replace(children: [nameLabel, versionView, copiedLabel, copiedObjectsView])
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
        let padding = Layout.basicPadding
        nameLabel.frame.origin = CGPoint(x: padding,
                                         y: bounds.height - nameLabel.frame.height - padding)
        _ = Layout.leftAlignment([versionView, Padding(), copiedLabel],
                                 minX: nameLabel.frame.maxX + padding,
                                 height: frame.height)
        let cow = bounds.width - copiedLabel.frame.maxX - padding
        copiedObjectsView.frame = CGRect(x: copiedLabel.frame.maxX, y: padding,
                                         width: max(cow, 10), height: bounds.height - padding * 2)
    }
    func updateCopiedObjectsView() {
        copiedObjectsView.array = copyManager.copiedObjects
        let padding = Layout.smallPadding
        let bounds = CGRect(x: 0,
                            y: 0,
                            width: objectViewWidth,
                            height: copiedObjectsView.bounds.height - padding * 2)
        copiedObjectsView.replace(children: copyManager.copiedObjects.map {
            return ($0 as? ViewExpression)?.view(withBounds: bounds, isSmall: true) ??
                ObjectView(object: $0, thumbnailView: nil, minFrame: bounds, isSmall: true)
        })
        updateCopiedObjectViewPositions()
    }
    func updateCopiedObjectViewPositions() {
        let padding = Layout.smallPadding
        _ = Layout.leftAlignment(copiedObjectsView.children, minX: padding, y: padding)
    }
    
    var rootUndoManager = UndoManager()
    override var undoManager: UndoManager? {
        return rootUndoManager
    }
    
    func copiedObjects(with event: KeyInputEvent) -> [Any]? {
        return copyManager.copiedObjects
    }
    func delete(with event: KeyInputEvent) -> Bool {
        guard !copyManager.copiedObjects.isEmpty else {
            return false
        }
        set(CopyManager(), old: copyManager)
        return true
    }
    func paste(_ copyManager: CopyManager, with event: KeyInputEvent) -> Bool {
        set(copyManager, old: self.copyManager)
        return true
    }
    private func set(_ copyManager: CopyManager, old oldCopyManager: CopyManager) {
        undoManager?.registerUndo(withTarget: self) {
            $0.set(oldCopyManager, old: copyManager)
        }
        self.rootCopyManager = copyManager
    }
}
