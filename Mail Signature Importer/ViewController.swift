//
//  ViewController.swift
//  Mail Signature Importer
//
//  Created by Carl Friess on 26/02/2017.
//  Copyright © 2017 Carl Friess. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var accountSelector: NSPopUpButton!
    @IBOutlet weak var signatureNameField: NSTextField!
    @IBOutlet weak var signatureField: NSTextField!
    

    var mailDataDirectory = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("/Library/Mail")

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: mailDataDirectory, includingPropertiesForKeys: nil, options: [])
            
            let possibleDirectories = ["V2", "V3", "V4"]
            var possibleDirectoriesHighestIndex = -1
            
            for item in directoryContents {
                let index = possibleDirectories.index(of: item.lastPathComponent) ?? -1
                if index > possibleDirectoriesHighestIndex {
                    possibleDirectoriesHighestIndex = index
                }
            }
            if possibleDirectoriesHighestIndex < 0 {
                return;
            }
            mailDataDirectory = mailDataDirectory.appendingPathComponent(possibleDirectories[possibleDirectoriesHighestIndex])
            mailDataDirectory = mailDataDirectory.appendingPathComponent("MailData")
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        if let accountMap = NSDictionary(contentsOf: mailDataDirectory.appendingPathComponent("Signatures/AccountsMap.plist")) {
            for account in accountMap {
                accountSelector.addItem(withTitle: ((account.value as! NSDictionary).object(forKey: "AccountURL")) as! String)
            }
        }
        
    }
    
    @IBAction func `import`(_ sender: Any) {
        
        let uuid = UUID().uuidString
        let signatureFile = "Content-Transfer-Encoding: quoted-printable\nContent-Type: text/html;\n\tcharset=us-ascii\nMessage-Id: <" + uuid + ">\nMime-Version: 1.0 (Mac OS X Mail 10.1 \\(3251\\)) \n\n" + (signatureField.stringValue)
        
        do {
            try signatureFile.write(to: mailDataDirectory.appendingPathComponent("Signatures/" + uuid + ".mailsignature"), atomically: false, encoding: .utf8)
        }
        catch {
            let myPopup: NSAlert = NSAlert()
            myPopup.messageText = "An error occured writing the signature file!"
            myPopup.alertStyle = .critical
            myPopup.runModal()
            return
        }
        
        let accountMapURL = mailDataDirectory.appendingPathComponent("Signatures/AccountsMap.plist")
        if let accountMap = NSMutableDictionary(contentsOf: accountMapURL) {
            for account in accountMap {
                if ((account.value as! NSMutableDictionary).object(forKey: "AccountURL")) as? String == accountSelector.selectedItem?.title {
                    ((account.value as! NSMutableDictionary).object(forKey: "Signatures") as! NSMutableArray).add(uuid)
                }
                print(accountMap)
            }
            accountMap.write(to: accountMapURL, atomically: false)
        }
        
        let signaturesURL = mailDataDirectory.appendingPathComponent("Signatures/AllSignatures.plist")
        if let signatures = NSMutableArray(contentsOf: signaturesURL) {
            let signatureDict: NSDictionary = [
                "SignatureIsRich": false,
                "SignatureName": signatureNameField.stringValue,
                "SignatureUniqueId": uuid
            ];
            signatures.add(signatureDict)
            signatures.write(to: signaturesURL, atomically: false)
        }
        
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = "Signature successfully added!"
        myPopup.informativeText = "Please quit and restart Mail!"
        myPopup.alertStyle = .informational
        myPopup.runModal()
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

