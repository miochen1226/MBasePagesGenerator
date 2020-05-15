//
//  DragHandleView.swift
//  ProjectMaker
//
//  Created by mio on 2020/5/13.
//  Copyright © 2020 miochen. All rights reserved.
//

import Cocoa

@objc protocol DragHandleViewDelegate: AnyObject {
    func draggingEntered(forDragHandleView dragHandleView: DragHandleView, sender: NSDraggingInfo) -> NSDragOperation
    func performDragOperation(forDragHandleView dragHandleView: DragHandleView, sender: NSDraggingInfo) -> Bool
    func pasteboardWriter(forDragHandleView dragHandleView: DragHandleView) -> NSPasteboardWriting
}

class DragHandleView: NSView,NSDraggingSource {
    
    @IBOutlet weak var delegate: DragHandleViewDelegate?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if isHighlighted {
            NSGraphicsContext.saveGraphicsState()
            NSFocusRingPlacement.only.set()
            bounds.insetBy(dx: 2, dy: 2).fill()
            NSGraphicsContext.restoreGraphicsState()
        }
    }
    
    var isHighlighted: Bool = false {
        didSet {
            needsDisplay = true
        }
    }
    
    // MARK: - NSDraggingSource
    
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return (context == .outsideApplication) ? [.copy] : []
    }
    
    // MARK: - NSDraggingDestination
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        var result: NSDragOperation = []
        if let delegate = delegate {
            result = delegate.draggingEntered(forDragHandleView: self, sender: sender)
            isHighlighted = (result != [])
        }
        return result
    }
        
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return delegate?.performDragOperation(forDragHandleView: self, sender: sender) ?? true
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        isHighlighted = false
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        isHighlighted = false
    }
    
}
