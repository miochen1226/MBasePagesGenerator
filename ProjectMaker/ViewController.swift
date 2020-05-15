//
//  ViewController.swift
//  ProjectMaker
//
//  Created by mio on 2020/5/12.
//  Copyright © 2020 miochen. All rights reserved.
//

import Cocoa

class ViewController: NSViewController,NSWindowDelegate {

    var myVC:MyVC?
    
    override func viewDidAppear() {
        view.window?.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        myVC = MyVC.init(nibName: "MyVC", bundle: nil)
        
        self.view.addSubview(myVC!.view)
        myVC!.view.frame = self.view.frame
        
        myVC!.view.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })

        //applyFitParent(view:self.view,viewSub: myVC!.view)

        // Do any additional setup after loading the view.
    }
    
    func windowDidResize(_ notification: Notification) {
        myVC!.view.frame = self.view.frame
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

