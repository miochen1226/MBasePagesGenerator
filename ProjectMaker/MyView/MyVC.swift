//
//  MyVC.swift
//  ProjectMaker
//
//  Created by mio on 2020/5/12.
//  Copyright © 2020 miochen. All rights reserved.
//

import Cocoa

class FoderObj:NSObject{
    var folderName = ""
    var arrayFiles:[String]=[]
}


class MyVC: NSViewController,NSFilePromiseProviderDelegate,DragHandleViewDelegate  {
    
    @IBOutlet weak var dragHandleView: DragHandleView!
    @IBOutlet weak var viewBG: NSView!
    @IBOutlet weak var textView: NSTextField!
    @IBOutlet private weak var imageView: NSImageView! {
        didSet{
            imageView.unregisterDraggedTypes()
        }
    }
    
    func draggingEntered(forDragHandleView dragHandleView: DragHandleView, sender: NSDraggingInfo) -> NSDragOperation {
         return sender.draggingSourceOperationMask.intersection([.copy])
    }
    
    func performDragOperation(forDragHandleView dragHandleView: DragHandleView, sender: NSDraggingInfo) -> Bool {
        let supportedClasses = [
            NSFilePromiseReceiver.self,
            NSURL.self
        ]

        let searchOptions: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true,
            .urlReadingContentsConformToTypes: [ kUTTypeFolder ]
        ]
        /// - Tag: HandleFilePromises
        sender.enumerateDraggingItems(options: [], for: nil, classes: supportedClasses, searchOptions: searchOptions) { (draggingItem, _, _) in
            switch draggingItem.item {
            case let filePromiseReceiver as NSFilePromiseReceiver:
                //self.prepareForUpdate()
                filePromiseReceiver.receivePromisedFiles(atDestination: self.destinationURL, options: [:],
                                                         operationQueue: self.workQueue) { (fileURL, error) in
                    if let error = error {
                        self.handleError(error)
                    } else {
                        self.handleFile(at: fileURL)
                    }
                }
            case let fileURL as URL:
                self.handleFile(at: fileURL)
            default: break
            }
        }
        
        return true
    }
    
    func pasteboardWriter(forDragHandleView dragHandleView: DragHandleView) -> NSPasteboardWriting {
        let provider = NSFilePromiseProvider(fileType: kUTTypeJPEG as String, delegate: self)
        return provider
    }
    
    /// Queue used for reading and writing file promises.
    private lazy var workQueue: OperationQueue = {
        let providerQueue = OperationQueue()
        providerQueue.qualityOfService = .userInitiated
        return providerQueue
    }()
    
    /// Directory URL used for accepting file promises.
    private lazy var destinationURL: URL = {
        let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Drops")
        try? FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        return destinationURL
    }()
    
    private func handleFile(at url: URL) {
        let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
        
        if(isDirectory)
        {
            OperationQueue.main.addOperation {
                self.processFolder(url: url)
            }
        }
    }
    
    var mapFileFolder:[String:FoderObj] = [:]
    
    func getFolderObj(folderID:String)->FoderObj?
    {
        if(folderID == "")
        {
            return nil
        }
        
        let foderObj = mapFileFolder[folderID] ?? nil
        if(foderObj == nil)
        {
            let newFoderObj = FoderObj()
            newFoderObj.folderName = ""
            mapFileFolder[folderID] = newFoderObj
            return newFoderObj
        }
        else
        {
            return foderObj
        }
    }
    
    func getFolderID_Ex(fileName:String)->String
    {
        let strArray = fileName.components(separatedBy: " ")
        var folderID = strArray[0]
        folderID = folderID.replace(target: "a", withString: "")
        folderID = folderID.replace(target: "b", withString: "")
        folderID = folderID.replace(target: "c", withString: "")
        folderID = folderID.replace(target: "d", withString: "")
        folderID = folderID.replace(target: "e", withString: "")
        return folderID
    }
    
    func getFolderObj(fileName:String)->FoderObj?
    {
        let folderID = getFolderID_Ex(fileName: fileName)
        return getFolderObj(folderID: folderID)
    }
    
    func createFolderObj(fileName:String)
    {
        let folderID = getFolderID(fileName: fileName)
        
        if(isValidFolderID(folderID))
        {
            let folderName = getFolderName(fileName:fileName)
            if(folderName == "")
            {
                return
            }
            
            if(mapFileFolder[folderID] == nil)
            {
                let newFoderObj = FoderObj()
                newFoderObj.folderName = folderName
                mapFileFolder[folderID] = newFoderObj
            }
        }
    }
    
    func getFolderName(fileName:String)->String
    {
        let strArray = fileName.components(separatedBy: " ")
        if(strArray.count == 1)
        {
            return ""
        }
        
        let folderName = strArray[1]
        
        if(folderName.contains("（"))
        {
            let folderName_ex = folderName.components(separatedBy: "（")[0]
            return folderName_ex
        }
        if(folderName.contains("("))
        {
            let folderName_ex = folderName.components(separatedBy: "(")[0]
            return folderName_ex
        }
        return folderName
    }
    
    func getFolderID(fileName:String)->String
    {
        let strArray = fileName.components(separatedBy: " ")
        let folderID = strArray[0]
        return folderID
    }
    
    func isValidFolderID(_ folderID: String) -> Bool {
        if(folderID.contains("a"))
        {
            return false
        }
        else if(folderID.contains("b"))
        {
            return false
        }
        else if(folderID.contains("c"))
        {
            return false
        }
        else if(folderID.contains("d"))
        {
            return false
        }
        
        return true
    }
    
    var copySrcFolder = ""
    var imageSrcCount = 0
    func processFolder(url: URL){
        let tempPath = url.path
        copySrcFolder = tempPath
        mapFileFolder = [:]
        
        imageSrcCount = 0
        do{
            let fileList = try FileManager.default.contentsOfDirectory(atPath: tempPath)
            for file in fileList{
                let fileName = file.fileName()
                let fileExt = file.fileExtension()
                if(fileExt == "png" || fileExt == "jpg")
                {
                    createFolderObj(fileName: fileName)
                }
            }
            
            //Collect images to FolderObj
            for file in fileList{
                let fileName = file.fileName()
                let fileExt = file.fileExtension()
                if(fileExt == "png" || fileExt == "jpg")
                {
                    let folderObj = getFolderObj(fileName: fileName)
                    let filePath = copySrcFolder + "/" + file
                    folderObj?.arrayFiles.append(filePath)
                    imageSrcCount += 1
                }
            }
        }
        catch{
            print("Cannot list directory")
        }
        
        textView.stringValue = "Discovered " + String(imageSrcCount) + "image(s)"
    }
    
    func writeSwiftFile(vcID:String,vcName:String,path:String)
    {
        let modifyVcName = vcName.replace(target: ".", withString: "_")
        let className = "MB_" + modifyVcName + "_" + "VC"
        let outputFilePath = path + "/" + className + ".swift"
        let outputFileURL = URL(fileURLWithPath: outputFilePath)
        
        let templatePath = Bundle.main.path(forResource: "template_swift", ofType: "txt")
        do {
            var contents = try String(contentsOfFile: templatePath!)
            contents = contents.replace(target: "{$CLASS_NAME}", withString: className)
            contents = contents.replace(target: "{$PAGE_ID}", withString: vcID)
            
            print(contents)
            
            do {
                try contents.write(to: outputFileURL, atomically: false, encoding: .utf8)
            }
            catch {/* error handling here */}
            
        } catch {
            // contents could not be loaded
        }
    }
    
    func writeXibFile(vcName:String,path:String)
    {
        let modifyVcName = vcName.replace(target: ".", withString: "_")
        let className = "MB_" + modifyVcName + "_" + "VC"
        let outputFilePath = path + "/" + className + ".xib"
        let outputFileURL = URL(fileURLWithPath: outputFilePath)
        let templatePath = Bundle.main.path(forResource: "template_xib", ofType: "txt")
        do {
            var contents = try String(contentsOfFile: templatePath!)
            contents = contents.replace(target: "{$CLASS_NAME}", withString: className)
            
            do {
                try contents.write(to: outputFileURL, atomically: false, encoding: .utf8)
            }
            catch {/* error handling here */}
        } catch {
            // contents could not be loaded
        }
    }
    
    /// Displays an error.
    private func handleError(_ error: Error) {
        OperationQueue.main.addOperation {
            if let window = self.view.window {
                self.presentError(error, modalFor: window, delegate: nil, didPresent: nil, contextInfo: nil)
            } else {
                self.presentError(error)
            }
        }
    }
    
    /// - Tag: RegisterPromiseReceiver
    override func viewDidLoad() {
        super.viewDidLoad()
        viewBG.wantsLayer = true
        viewBG.alphaValue = 0.3
        
        let NSFilenamesPboardTypeTemp = NSPasteboard.PasteboardType("NSFilenamesPboardType")

        self.view.registerForDraggedTypes([NSFilenamesPboardTypeTemp])
        
        textView.stringValue = "Waiting for drag input"
    }
    
    func cleanOuputFolder(path:String)
    {
        do
        {
            try FileManager.default.removeItem(at: URL(fileURLWithPath: path))
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        catch
        {
        }
    }
    
    func createOutputFolder()
    {
        let path: String = userDesktop() + "/Pages"
        cleanOuputFolder(path: path)
        
        var imageCount = 0
        for key in mapFileFolder.keys
        {
            let folderObj = mapFileFolder[key]
            if(folderObj != nil)
            {
                var finalFolderName = key + " "
                finalFolderName = finalFolderName + folderObj!.folderName
                let newFolderPath = path + "/" + finalFolderName
                let newSnapShotFolderPath = newFolderPath + "/" + "screen"
                
                do
                {
                    let vcID = finalFolderName
                    try FileManager.default.createDirectory(atPath: newFolderPath, withIntermediateDirectories: true, attributes: nil)
                    
                    try FileManager.default.createDirectory(atPath: newSnapShotFolderPath, withIntermediateDirectories: true, attributes: nil)
                    
                    //Copy image files
                    for filePath in folderObj?.arrayFiles ?? [] {
                        let srcPath = filePath
                        let tarPath = filePath.replace(target: copySrcFolder, withString: newSnapShotFolderPath)
                        let srcURL = URL(fileURLWithPath: srcPath)
                        let tarURL = URL(fileURLWithPath: tarPath)
                        _ = FileManager.default.secureCopyItem(at: srcURL, to: tarURL)
                        imageCount += 1
                    }
                    
                    //Create TemplateFile
                    writeSwiftFile(vcID:vcID, vcName:key,path:newFolderPath)
                    writeXibFile(vcName:key,path: newFolderPath)
                }
                catch _ as NSError
                {
                }
            }
        }
        
        textView.stringValue = "Complete" + String(imageCount) + "/" + String(imageSrcCount) + "image(s)"
    }
    
    public func userDesktop() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true)
        let userDesktopDirectory = paths[0]
        return userDesktopDirectory
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
        view.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
    }
    
    // MARK: - NSFilePromiseProviderDelegate
    
    /// - Tag: ProvideFileName
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        let droppedFileName = NSLocalizedString("DropFileTitle", comment: "")
        return droppedFileName + ".jpg"
    }
    
    /// - Tag: ProvideOperationQueue
    func operationQueue(for filePromiseProvider: NSFilePromiseProvider) -> OperationQueue {
        return workQueue
    }
    
    /// - Tag: PerformFileWriting
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping (Error?) -> Void) {
        completionHandler(nil)
    }
    
    @IBAction func didExportClicked(button: NSButton)
    {
        createOutputFolder()
    }
}

extension String{
    func replace(target: String, withString: String) -> String
    {
        return self.replacingOccurrences(of: target, with: withString, options: NSString.CompareOptions.literal, range: nil)
    }
}

extension String {

    func fileName() -> String {
        return URL(fileURLWithPath: self).deletingPathExtension().lastPathComponent
    }

    func fileExtension() -> String {
        return URL(fileURLWithPath: self).pathExtension
    }
}

extension FileManager {

    open func secureCopyItem(at srcURL: URL, to dstURL: URL) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: dstURL.path) {
                try FileManager.default.removeItem(at: dstURL)
            }
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
        } catch (let error) {
            print("Cannot copy item at \(srcURL) to \(dstURL): \(error)")
            return false
        }
        return true
    }

}
