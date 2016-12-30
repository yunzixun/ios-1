//
//  DocumentPickerViewController.swift
//  Picker
//
//  Created by Marino Faggiana on 27/12/16.
//  Copyright © 2016 TWS. All rights reserved.
//
//  Author Marino Faggiana <m.faggiana@twsweb.it>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import UIKit

class DocumentPickerViewController: UIDocumentPickerExtensionViewController, CCNetworkingDelegate {
    
    // MARK: - Properties
    
    var provider : providerSession?
    
    var metadata : CCMetadata?
    var recordsTableMetadata : [TableMetadata]?
    
    var activeAccount : String?
    var activeUrl : String?
    var activeUser : String?
    var activePassword : String?
    var activeUID : String?
    var activeAccessToken : String?
    var directoryUser : String?
    var typeCloud : String?
    var serverUrl : String?
    
    var localServerUrl : String?
    
    lazy var networkingOperationQueue : OperationQueue = {
        
        var queue = OperationQueue()
        queue.name = "it.twsweb.cryptocloud.queue"
        queue.maxConcurrentOperationCount = 1
        
        return queue
    }()
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        
        provider = providerSession.sharedInstance
        
        if let record = CCCoreData.getActiveAccount() {
            
            activeAccount = record.account!
            activePassword = record.password!
            activeUrl = record.url!
            activeUser = record.user!
            typeCloud = record.typeCloud!
            directoryUser = CCUtility.getDirectoryActiveUser(activeUser!, activeUrl: activeUrl!)
            
            if (localServerUrl == nil) {
            
                localServerUrl = CCUtility.getHomeServerUrlActiveUrl(activeUrl!, typeCloud: typeCloud!)
            }
            
        } else {
            
            // Close error no account return nil
            
            let deadlineTime = DispatchTime.now() + 0.1
            DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                
                let alert = UIAlertController(title: NSLocalizedString("_error_", comment: ""), message: NSLocalizedString("_no_active_account_", comment: ""), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .default) { action in
                    self.dismissGrantingAccess(to: nil)
                })
                
                self.present(alert, animated: true, completion: nil)
            }

            return
        }
        
        CCNetworking.shared().settingDelegate(self)
        
        // COLOR_SEPARATOR_TABLE
        self.tableView.separatorColor = UIColor(colorLiteralRed: 153.0/255.0, green: 153.0/255.0, blue: 153.0/255.0, alpha: 0.2)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        let directoryID : String? = CCCoreData.getDirectoryID(fromServerUrl: localServerUrl!, activeAccount: activeAccount!)
        let predicate = NSPredicate(format: "(account == %@) AND (directoryID == %@)", activeAccount!, directoryID!)
        
        recordsTableMetadata = CCCoreData.getTableMetadata(with: predicate, fieldOrder: CCUtility.getOrderSettings()!, ascending: CCUtility.getAscendingSettings()) as? [TableMetadata]
                
        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate

extension DocumentPickerViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
         return 60
    }
}

// MARK: - UITableViewDataSource

extension DocumentPickerViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if (recordsTableMetadata == nil) {
            return 0
        } else {
            return recordsTableMetadata!.count
        }
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! recordMetadataCell
        
        cell.separatorInset = UIEdgeInsetsMake(0, 60, 0, 0)
        
        let recordTableMetadata = recordsTableMetadata?[(indexPath as NSIndexPath).row]
        let metadata = CCCoreData.insertEntity(in: recordTableMetadata)!
        
        // File Image View
        let filePath = directoryUser!+"/"+metadata.fileID!+".ico"
        
        if (FileManager.default.fileExists(atPath: filePath)) {
            
            cell.fileImageView.image = UIImage(contentsOfFile: filePath)
            
        } else {
            
            cell.fileImageView.image = UIImage(named: metadata.iconName!)
        }
        
        // File Name
        cell.FileName.text = metadata.fileNamePrint!
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let recordTableMetadata = recordsTableMetadata?[(indexPath as NSIndexPath).row]
        
        let nextViewController = self.storyboard?.instantiateViewController(withIdentifier: "DocumentPickerViewController") as! DocumentPickerViewController
        
        nextViewController.localServerUrl = CCUtility.stringAppendServerUrl(localServerUrl!, addServerUrl: recordTableMetadata!.fileName)
        
        self.navigationController?.pushViewController(nextViewController, animated: true)
        
    }
}

// MARK: - Class UITableViewCell

class recordMetadataCell: UITableViewCell {
    
    @IBOutlet weak var fileImageView: UIImageView!
    @IBOutlet weak var FileName : UILabel!
}

// MARK: - Class providerSession

class providerSession {
    
    class var sharedInstance : providerSession {
        
        struct Static {
            
            static let instance = providerSession()
        }
        
        return Static.instance
    }
    
    private init() {
    
        let dirGroup = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: capabilitiesGroups)
        let pathDB = dirGroup?.appendingPathComponent(appDatabase).appendingPathComponent("cryptocloud")
        
        MagicalRecord.setupCoreDataStackWithAutoMigratingSqliteStore(at: pathDB!)
        MagicalRecord.setLoggingLevel(MagicalRecordLoggingLevel.off)
    }
}