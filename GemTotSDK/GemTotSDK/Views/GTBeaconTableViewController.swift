//
//  GTBeaconTableViewController.swift
//  GemTotSDK
//
//  Copyright (c) 2014 PassKit, Inc.
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


import UIKit

class GTBeaconTableViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    // Constants - form elements
    let _toggleSwitch : UISwitch = UISwitch()
    let _dbPicker : UIPickerView = UIPickerView()
    let _numberToolbar : UIToolbar = UIToolbar(frame: CGRectMake(0.0,0.0,320.0,50.0))

    // Shared objects
    let _iBeaconConfig : GTStorage = GTStorage.sharedGTStorage // Dictionary containing beacon config parameters
    let _beacon : GTBeaconBroadcaster = GTBeaconBroadcaster.sharedGTBeaconBroadcaster // Shared instance to allow continuous broadcasting after this view is dismissed
    
   
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
        
        // Subscribe to notifications on toggle changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "toggleStatus:", name: "iBeaconBroadcastStatus", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onKeyboardHide:", name: UIKeyboardDidHideNotification, object: nil)
        
        // Conifgure the toolbar and pickerview
        configureToolbarToggleAndPicker()
        
        // Add a gesture recognizer to make dismissing the keyboard easier
        addTapGestureRecognizers()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /**************************************************************************************
    *
    *  Helper Functions
    *
    **************************************************************************************/
    
    // Configures the view components ready for viewing
    func configureToolbarToggleAndPicker() {
        
        // Configure the toolbar that sits above the numeric keypad
        let toolbarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: NSLocalizedString("Done", comment: "Button to accept the iBeacon paramaters and dismiss the keyboard"), style: .Plain, target: self, action: "dismissKeyboard:")
        ]
        
        _numberToolbar.setItems(toolbarButtonItems, animated:false)
        _numberToolbar.barStyle = UIBarStyle.Default
        _numberToolbar.translucent = true
        _numberToolbar.sizeToFit()
        
        // Configure the date picker
        _dbPicker.dataSource = self;
        _dbPicker.delegate = self;
        _dbPicker.backgroundColor = UIColor.whiteColor()
        
        // Configure the toggle
        _toggleSwitch.setOn(_beacon.beaconStatus(), animated: false)
        _toggleSwitch.addTarget(self, action: "toggleBeacon:", forControlEvents: UIControlEvents.ValueChanged)
        
    }
    
    // Adds a tap gesture to the background to dismiss the keyboard if users click outside of the keyboard of input cells and a tap gesture to the table footer to copy the UUID to the clipboard
    func addTapGestureRecognizers() {
        
        let tapBackground : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard:")
        self.view.addGestureRecognizer(tapBackground)
        
    }
    
    // Copy the UUID to the clipboard
    func copyUUID(sender: AnyObject) {
        
        let UUID = _iBeaconConfig.getValue("UUID", fromStore:"iBeacon") as! String
        let pasteBoard: UIPasteboard = UIPasteboard.generalPasteboard()
        pasteBoard.string = UUID
        
        let alert = UIAlertController(title: NSLocalizedString("UUID copied clipboard", comment:"Alert UUID Copied to Clipboard"), message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        alert.message = "\n" + UUID
        alert.addAction(UIAlertAction(title: NSLocalizedString("Okay", comment:"OK button used to dismiss alerts"), style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // callback funciton called whenever the toggle changes state
    func toggleBeacon(sender :AnyObject!) {
        
        let button = sender as! UISwitch
        let state = button.on
        
        if (state == true) {
            let beaconStarted = _beacon.startBeacon()
            if (beaconStarted.success == false) {
                _toggleSwitch.setOn(false, animated: false)
                let alert = UIAlertController(title: NSLocalizedString("Error Starting Beacon", comment:"Alert title for problemn starting beacon"), message: nil, preferredStyle: UIAlertControllerStyle.Alert)
                alert.message = beaconStarted.error as? String
                alert.addAction(UIAlertAction(title: NSLocalizedString("Okay", comment:"OK button used to dismiss alerts"), style: UIAlertActionStyle.Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        
        } else {
            _beacon.stopBeacon()
        }
        
        // Reload the table to update the table footer message
        self.tableView.reloadData()
    }
    
    
    func toggleStatus(notification: NSNotification) {
        
        let packageContents : NSDictionary = notification.userInfo! as Dictionary
        
        _toggleSwitch.setOn(packageContents.objectForKey("broadcastStatus") as! Bool, animated: false)
        
        if (packageContents.objectForKey("broadcastStatus") as! Bool) {
            
            if (!_beacon.beaconStatus()) {
                _beacon.startBeacon()
            }
        }

        self.tableView.reloadData()
    }
    
    // Utility function to construct the footer message containin the advertising paramaters
    func footerString() -> String {
        
        let UUID = _iBeaconConfig.getValue("UUID", fromStore:"iBeacon") as! String
        
        // Hack to ensure toggle is correctly set on first startup
        _toggleSwitch.setOn(_beacon.beaconStatus(), animated: false)
        
        // If the device is broadcasting, construct a string containing the advertising paramaters
        if (_beacon.beaconStatus() == true) {
            
            // retrieve the current values from the config dictionary
            let major = _iBeaconConfig.getValue("major", fromStore:"iBeacon") as! NSNumber
            let minor = _iBeaconConfig.getValue("minor", fromStore:"iBeacon") as! NSNumber
            let power = _iBeaconConfig.getValue("power", fromStore: "iBeacon") as! NSNumber
            
            // Construct a readable string from the power value
            var powerString : String
            
            if (power.integerValue == 127) {
                
                powerString = NSLocalizedString("Device Default", comment:"Label shown in table cell to indicate deivce will broadcast the default measured power")
                
            } else {
                let sign = (power.integerValue <= 0  ? "" : "+")
                powerString = "\(sign)\(power)dB"
            }
            
            // Put it all together
            let footerString = String.localizedStringWithFormat(NSLocalizedString("Broadcasting beacon signal\n\nUUID: %@\nMajor: %@; Minor: %@\nMeasured Power: %@", comment:"Structured message to display the paramaters of the beacon signal that is currently being broadcast"), UUID, major, minor, powerString)
            
            return footerString
            
        } else {
            
            let footerString = String.localizedStringWithFormat(NSLocalizedString("UUID: %@\n\nThis device is not broadcasting a beacon signal", comment:"Text at bottom of iBeacon view when not broadcasting an iBeacon signal"), UUID)
            
            return footerString
        }
        
    }

    func dismissKeyboard(sender: AnyObject) {
        self.view.endEditing(true)
    }
    
    // Reloads the table to update the footer message whenever the keyboard is dismissed
    func onKeyboardHide(notification: NSNotification!) {
        self.tableView.reloadData()
    }
    
    // Function to check if string is a UUID, or to generate a constant UUID from a string
    func UUIDforString(UUIDNameOrString: String) -> String {
        
        // Test if UUIDNameOrString is a valid UUID, and if so, set the return it
        let range = UUIDNameOrString.rangeOfString("^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[1-5][0-9A-Fa-f]{3}-[89ABab][0-9A-Fa-f]{3}-[0-9A-Fa-f]{12}$", options: .RegularExpressionSearch)
        
        if (range != nil && UUIDNameOrString.characters.count == 36) {
            
          return UUIDNameOrString
            
        } else {
            
            //var ccount: UInt16 = 16 + UUIDNameOrString.characters.count.value as UInt16
            
            // Variable to hold the hashed namespace
            let hashString = NSMutableData()
            
            // Unique seed namespace - keep to generate UUIDs compatible with PassKit, or change to avoid conflicts
            // Needs to be a hexadecimal value - ideally a UUID
            let nameSpace: String = "b8672a1f84f54e7c97bdff3e9cea6d7a"
            
            // Convert each byte of the seed namespace to a character value and append the character byte
            for var i = 0; i < nameSpace.characters.count; i+=2 {
                
                var charValue: UInt32 = 0
                let s = "0x" + String(Array(nameSpace.characters)[i]) + String(Array(nameSpace.characters)[i+1])

                NSScanner(string: s).scanHexInt(&charValue)
                hashString.appendBytes(&charValue, length: 1)
            }
            
            // Append the UUID String bytes to the hash input
            let uuidString: NSData = NSString(format:UUIDNameOrString, NSUTF8StringEncoding).dataUsingEncoding(NSUTF8StringEncoding)!
            hashString.appendBytes(uuidString.bytes, length: uuidString.length)
            
            // SHA1 hash the input
            let rawUUIDString = String(hashString.sha1())
            
            // Build the UUID string as defined in RFC 4122
            var part3: UInt32 = 0
            var part4: UInt32 = 0
            NSScanner(string: (rawUUIDString as NSString).substringWithRange(NSMakeRange(12, 4))).scanHexInt(&part3)
            NSScanner(string: (rawUUIDString as NSString).substringWithRange(NSMakeRange(16, 4))).scanHexInt(&part4)
            let uuidPart3 = String(NSString(format:"%2X", (part3 & 0x0FFF) | 0x5000))
            let uuidPart4 = String(NSString(format:"%2X", (part4 & 0x3FFF) | 0x8000))
            
            return  "\((rawUUIDString as NSString).substringWithRange(NSMakeRange(0, 8)))-" +
                    "\((rawUUIDString as NSString).substringWithRange(NSMakeRange(8, 4)))-" +
                    "\(uuidPart3.lowercaseString)-" +
                    "\(uuidPart4.lowercaseString)-" +
                    "\((rawUUIDString as NSString).substringWithRange(NSMakeRange(20, 12)))"
        }
    }
    
    
    
    /**************************************************************************************
    *
    *  UITable View Delegate Functions
    *
    **************************************************************************************/
    
    override func numberOfSectionsInTableView(tableView: UITableView?) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return 1
        } else {
            return 4
        }
    }
    
    override func tableView(tableView: UITableView?, didSelectRowAtIndexPath indexPath: NSIndexPath?) {
        tableView!.userInteractionEnabled = false
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (indexPath.section == 0) {
        
            let cell :UITableViewCell? = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "iBeaconToggle")
        
            // Add the image to the table cell
            let cellImage = UIImage(named:"iBeaconTableCell")
            if let imageView = cell?.imageView {
                imageView.image = cellImage
            } else {
                NSLog("imageView is nil")
            }

            // Set the cell label
            if let textLabel = cell?.textLabel {
                textLabel.text = NSLocalizedString("Broadcast Signal", comment:"Label of iBeacon Toggle to start or stop broadcasting as an iBeacon") as String
                textLabel.font = UIFont.systemFontOfSize(16.0)
            } else {
                NSLog("textLabel is nil")
            }

            // Add the toggle to the table cell and
            cell?.accessoryView = UIView(frame: _toggleSwitch.frame)
            if let accessoryView = cell?.accessoryView {
                accessoryView.addSubview(_toggleSwitch)
            } else {
                NSLog("accessoryView is nil")
            }

            // Make the cell non-selectable (only the toggle will be active)
            cell?.selectionStyle = UITableViewCellSelectionStyle.None

            return cell!
    
        } else {
            let cell :UITableViewCell? = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "iBeaconCell")
            
            
            let iBeaconParamsLabels = [
                NSLocalizedString("Name or UUID", comment:"Tabel cell label for beacon name or UUID value"),
                NSLocalizedString("Major Value", comment:"Table cell label for beacon major value"),
                NSLocalizedString("Minor Value", comment:"Table cell label for beacon minor value"),
                NSLocalizedString("Measured Power", comment:"Table cell label for beacon measured power value")
            ]
            
            // Set the cell label
            if let textLabel = cell?.textLabel {
                textLabel.text = iBeaconParamsLabels[indexPath.row]
                textLabel.font = UIFont.systemFontOfSize(16.0)
            } else {
                NSLog("textLabel is nil")
            }

            // Create and add a text field to the cell that will contain the value
            let optionalMargin: CGFloat = 10.0
            let valueField = UITextField(frame: CGRectMake(170, 10, cell!.contentView.frame.size.width - 170 - optionalMargin, cell!.contentView.frame.size.height - 10 - optionalMargin))
            valueField.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
            valueField.delegate = self
            valueField.returnKeyType = UIReturnKeyType.Done
            valueField.clearButtonMode = UITextFieldViewMode.WhileEditing
            valueField.font = UIFont.systemFontOfSize(16.0)
            cell?.contentView.addSubview(valueField)
            
            switch (indexPath.row) {
                
            // Populate the value for each cell and configure the field UI as apporpriate for each value type
            case 0:
                valueField.text = _iBeaconConfig.getValue("beaconName", fromStore: "iBeacon") as? String
                valueField.placeholder = NSLocalizedString("Name or UUID", comment:"Placehoder text for iBeacon name field")
                valueField.tag = 1
            
            case 1:
                valueField.text = (_iBeaconConfig.getValue("major", fromStore: "iBeacon") as! NSNumber).stringValue
                valueField.placeholder = NSLocalizedString("0 - 65,535", comment:"iBeacon Major and Minor placehoder (represents min and max values)")
                valueField.keyboardType = UIKeyboardType.NumberPad
                valueField.inputAccessoryView = _numberToolbar
                valueField.tag = 2
                
            case 2:
                valueField.text = (_iBeaconConfig.getValue("minor", fromStore: "iBeacon") as! NSNumber).stringValue
                valueField.placeholder = NSLocalizedString("0 - 65,535", comment:"iBeacon Major and Minor placehoder (represents min and max values)")
                valueField.keyboardType = UIKeyboardType.NumberPad
                valueField.inputAccessoryView = _numberToolbar
                valueField.tag = 3

            case 3:
                let powerValue = _iBeaconConfig.getValue("power", fromStore: "iBeacon") as! Int
            
                if (powerValue == 127) {
                    valueField.text = NSLocalizedString("Device Default", comment:"Label shown in table cell to indicate deivce will broadcast the default measured power")
                } else {
                    let sign = (powerValue <= 0  ? "" : "+")
                    valueField.text = "\(sign)\(powerValue)dB"
                }
                valueField.tag = 4
                valueField.inputView = _dbPicker
                valueField.inputAccessoryView = _numberToolbar
                valueField.clearButtonMode = UITextFieldViewMode.Never
                valueField.tintColor = UIColor.clearColor() // This will hide the flashing cursor
                
            default:
                break
            }
            return cell!
        }
    }

    //Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView?, canEditRowAtIndexPath indexPath: NSIndexPath?) -> Bool {
        return false
    }

    //Override to support custom section headers.
    override func tableView(tableView: UITableView?, titleForHeaderInSection section: Int) -> String? {
        
        if (section == 0) {
            return NSLocalizedString("Beacon Status", comment: "Header of first section of iBeacon view")
            
        } else if (section == 1) {
            return NSLocalizedString("Beacon Paramaers", comment: "Header of second section of iBeacon view")
        }
        
        return nil
    }


    override func tableView(tableView: UITableView?, viewForFooterInSection section: Int) -> UIView? {
        
        if (section == 1) {
            
            let label: UILabel = UILabel()
            label.userInteractionEnabled = true
            label.text = footerString()
            label.baselineAdjustment = UIBaselineAdjustment.AlignBaselines;

            label.font = UIFont.systemFontOfSize(UIFont.smallSystemFontSize())
            label.textColor = UIColor.grayColor()
            label.numberOfLines = 0
            label.sizeToFit()
            
            var frame: CGRect = label.frame
            let view: UIView = UIView()
            view.frame = frame
            
            // Add padding to align label to Table View
            frame.origin.x = 15;
            frame.origin.y = 5;
            frame.size.width = self.view.bounds.size.width - frame.origin.x;
            frame.size.height = frame.size.height + frame.origin.y;
            label.frame = frame;
            
            view.addSubview(label)
            view.sizeToFit()

            // Add a Gesture Recognizer to copy the UUID to the Clipboard
            let tapTableFooter : UITapGestureRecognizer = UITapGestureRecognizer (target: self, action: "copyUUID:")
            tapTableFooter.numberOfTapsRequired = 1
            label.addGestureRecognizer(tapTableFooter)

            return view
        }
        
        return nil
    }
    
    override func tableView(tableView: UITableView?, heightForFooterInSection section: Int) -> CGFloat {
    
        if (section == 1) {
            return 100;
        }
        
        return 0;
    }
    
    
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView?, canMoveRowAtIndexPath indexPath: NSIndexPath?) -> Bool {
        return false
    }


    /**************************************************************************************
    *
    *  UIPickerView Data Source and Delegate Functions
    *
    **************************************************************************************/
    
    func pickerView(_: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {

        if (row == 0) {
            // Set the first row of the picker view as an option to select the device default measured power
            return NSLocalizedString("Use Device Default Value", comment:"Description for selecting the device default power, shown on the pickser wheel.  Should be kept concise")

        } else {
            // Construct the a string to return.  Negative values will already be prexied with a minus sign
            let sign = (row < 102 ? "" : "+")
            return "\(sign)\(row - 101)dB"
        }
    }

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        // -100dB to +100dB inclusive plus an option to select device default measured power
        return 202
    }
    
    /**************************************************************************************
    *
    *  UITextField Delegate Functions
    *
    **************************************************************************************/
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        // Dismiss the keyboard
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        
        switch (textField.tag) {
            
        case 1:
            // Replace empty string with a default value
            if (textField.text == "") {
                textField.text = "GemTot iOS"
            }

        case 2...3:
            
            // Validate the major and minor values before accepting.  If invalid, throw an alert and empty the field
            if (Int(textField.text!) > 0xFFFF) {
                let alert = UIAlertController(title: NSLocalizedString("Invalid Value", comment:"Alert title for invalid values"), message: nil, preferredStyle: UIAlertControllerStyle.Alert)
                alert.message = NSLocalizedString("Major and Minor keys can only accept a value between 0 and 65,535", comment:"Alert message to show if user enters an invalid Major or Minor value")
                alert.addAction(UIAlertAction(title: NSLocalizedString("Okay", comment:"OK button used to dismiss alerts"), style: UIAlertActionStyle.Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                
                textField.text = ""
            
                return false
            }
            
            // If an empty filed is submitted, replace with a 0 value
            if (textField.text == "") {
                textField.text = "0"
                return true
            }
            
        case 4:
            // Check if the picker view value is different to the field value and if so, update the field value and the config dictionary
            let row = _dbPicker.selectedRowInComponent(0)
            
            var targetText = ""
            
            if (row == 0) {
                targetText = NSLocalizedString("Device Default", comment:"Label shown in table cell to indicate deivce will broadcast the default measured power")
            } else {
                targetText = self.pickerView(_dbPicker, titleForRow: row, forComponent: 0)!
            }
            
            if (textField.text != targetText) {
                
                textField.text = targetText
                let dBValue: NSNumber = (row == 0 ? 127 : row - 101)
                _iBeaconConfig.writeValue(dBValue as NSNumber, forKey: "power", toStore: "iBeacon")
                
            }
        default:
            
            return true
        }
        
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        
        // Store the updated values in the config dictionary
        switch (textField.tag) {
            
        case 1:
            _iBeaconConfig.writeValue(textField.text, forKey:"beaconName", toStore:"iBeacon")
            _iBeaconConfig.writeValue(UUIDforString(textField.text!), forKey:"UUID", toStore:"iBeacon")
            
        case 2:
            _iBeaconConfig.writeValue(Int(textField.text!)!, forKey: "major", toStore: "iBeacon")
            
        case 3:
            _iBeaconConfig.writeValue(Int(textField.text!)!, forKey: "minor", toStore: "iBeacon")
            
        default:
            break
        }
        
        // If the beacon is broadcasting - dispatch a job to restart the beacon which will pick up the new values
        if (_toggleSwitch.on) {
            dispatch_async(dispatch_get_main_queue(), {_ = self._beacon.startBeacon()})
        }
        
        // Dismiss the keyboard
        textField.resignFirstResponder()
    }
    

    @IBAction func openSourceCode(sender: AnyObject) {
        UIApplication.sharedApplication().openURL(NSURL(string: "http://github.com/gemtot")!)
    }
    
    @IBAction func buyBeacons(sender: AnyObject) {
        UIApplication.sharedApplication().openURL(NSURL(string: "http://gemtot.com/")!)
    }
}