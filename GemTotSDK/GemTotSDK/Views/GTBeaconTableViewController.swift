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
    
    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
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
        addTapGestureRecognizer()

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
    
    // Adds a tap gesture to the background to dismiss the keyboard if users click outside of the keyboard of input cells
    func addTapGestureRecognizer() {
        
        let tapBackground : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard:")
        self.view.addGestureRecognizer(tapBackground)
        
    }
    
    // callback funciton called whenever the toggle changes state
    func toggleBeacon(sender :AnyObject!) {
        
        let state = sender.isOn
        
        if (state == true) {
            _beacon.startBeacon()
        } else {
            _beacon.stopBeacon()
        }
        
        // Reload the table to update the table footer message
        self.tableView.reloadData()
    }
    
    
    func toggleStatus(notification: NSNotification) {
        
        let packageContents : NSDictionary = notification.userInfo! as Dictionary
        
        _toggleSwitch.setOn(packageContents.objectForKey("broadcastStatus") as Bool, animated: false)
        
        if (packageContents.objectForKey("broadcastStatus") as Bool) {
            
            if (!_beacon.beaconStatus()) {
                _beacon.startBeacon()
            }
        }

        self.tableView.reloadData()
    }
    
    // Utility function to construct the footer message containin the advertising paramaters
    func footerString() -> String {
        
        // If the device is broadcasting, construct a string containing the advertising paramaters
        if (_beacon.beaconStatus() == true) {
            
            // retrieve the current values from the config dictionary
            let UUID = _iBeaconConfig.getValue("UUID", fromStore:"iBeacon") as String
            let major = _iBeaconConfig.getValue("major", fromStore:"iBeacon") as NSNumber
            let minor = _iBeaconConfig.getValue("minor", fromStore:"iBeacon") as NSNumber
            let power = _iBeaconConfig.getValue("power", fromStore: "iBeacon") as NSNumber
            
            // Construct a readable string from the power value
            var powerString : String
            
            if (power.integerValue == 127) {
                
                powerString = NSLocalizedString("Device Default", comment:"Label shown in table cell to indicate deivce will broadcast the default measured power")
                
            } else {
                let sign = (power.integerValue <= 0  ? "" : "+")
                powerString = "\(sign)\(power)dB"
            }
            
            // Put it all together
            let footerString = String.localizedStringWithFormat(NSLocalizedString("Broadcasting UUID: \n%@\n\nMajor: %@; Minor: %@\nMeasured Power: %@", comment:"Structured message to display the paramaters of the beacon signal that is currently being broadcast"), UUID, major, minor, powerString)
            
            return footerString
            
        } else {
            
            let footerString = NSLocalizedString("This device is not broadcasting an iBeacon signal", comment:"Text at bottom of iBeacon view when not broadcasting an iBeacon signal")
            
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
   
    override func tableView(tableView: UITableView?, cellForRowAtIndexPath indexPath: NSIndexPath?) -> UITableViewCell? {
        
        if (indexPath!.section == 0) {
        
            var cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "iBeaconToggle")
        
            // Add the image to the table cell
            let cellImage = UIImage(named:"iBeaconTableCell")
            cell.imageView.image = cellImage
                
            // Set the cell label
            cell.textLabel.text = NSLocalizedString("Broadcast Signal", comment:"Label of iBeacon Toggle to start or stop broadcasting as an iBeacon") as String
            cell.textLabel.font = UIFont.systemFontOfSize(16.0)
                
            // Add the toggle to the table cell and
            cell.accessoryView = UIView(frame: _toggleSwitch.frame)
            cell.accessoryView.addSubview(_toggleSwitch)
                
            // Make the cell non-selectable (only the toggle will be active)
            cell.selectionStyle = UITableViewCellSelectionStyle.None

            return cell
    
        } else {
            var cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "iBeaconCell")
            
            
            let iBeaconParamsLabels = [
                NSLocalizedString("iBeacon Name", comment:"Tabel cell label for beacon name or UUID value"),
                NSLocalizedString("Major Value", comment:"Table cell label for beacon major value"),
                NSLocalizedString("Minor Value", comment:"Table cell label for beacon minor value"),
                NSLocalizedString("Measured Power", comment:"Table cell label for beacon measured power value")
            ]
            
            // Set the cell label
            cell.textLabel.text = iBeaconParamsLabels[indexPath!.row]
            cell.textLabel.font = UIFont.systemFontOfSize(16.0)
                
            // Create and add a text field to the cell that will contain the value
            let optionalMargin: CGFloat = 10.0
            var valueField = UITextField(frame: CGRectMake(170, 10, cell.contentView.frame.size.width - 170 - optionalMargin, cell.contentView.frame.size.height - 10 - optionalMargin))
            valueField.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
            valueField.delegate = self
            valueField.returnKeyType = UIReturnKeyType.Done
            valueField.clearButtonMode = UITextFieldViewMode.WhileEditing
            valueField.font = UIFont.systemFontOfSize(16.0)
            cell.contentView.addSubview(valueField)
            
            switch (indexPath!.row) {
                
            // Populate the value for each cell and configure the field UI as apporpriate for each value type
            case 0:
                valueField.text = _iBeaconConfig.getValue("beaconName", fromStore: "iBeacon") as String
                valueField.placeholder = NSLocalizedString("Name or UUID", comment:"Placehoder text for iBeacon name field")
                valueField.tag = 1
            
            case 1:
                valueField.text = (_iBeaconConfig.getValue("major", fromStore: "iBeacon") as NSNumber).stringValue
                valueField.placeholder = NSLocalizedString("0 - 65,535", comment:"iBeacon Major and Minor placehoder (represents min and max values)")
                valueField.keyboardType = UIKeyboardType.NumberPad
                valueField.inputAccessoryView = _numberToolbar
                valueField.tag = 2
                
            case 2:
                valueField.text = (_iBeaconConfig.getValue("minor", fromStore: "iBeacon") as NSNumber).stringValue
                valueField.placeholder = NSLocalizedString("0 - 65,535", comment:"iBeacon Major and Minor placehoder (represents min and max values)")
                valueField.keyboardType = UIKeyboardType.NumberPad
                valueField.inputAccessoryView = _numberToolbar
                valueField.tag = 3

            case 3:
                let powerValue = _iBeaconConfig.getValue("power", fromStore: "iBeacon") as Int
            
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
            return cell
        }
    }

    //Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView?, canEditRowAtIndexPath indexPath: NSIndexPath?) -> Bool {
        return false
    }

    //Override to support custom section headers.
    override func tableView(tableView: UITableView?, titleForHeaderInSection section: Int) -> String? {
        
        if (section == 0) {
            return NSLocalizedString("iBeacon Status", comment: "Header of first section of iBeacon view")
            
        } else if (section == 1) {
            return NSLocalizedString("iBeacon Paramaers", comment: "Header of second section of iBeacon view")
        }
        
        return nil
    }


    override func tableView(tableView: UITableView?, titleForFooterInSection section: Int) -> String? {
        
        if (section == 1) {
            
            return footerString()
            
        }
        
        return nil
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
    
    func pickerView(_: UIPickerView?, titleForRow row: Int, forComponent component: Int) -> String! {

        if (row == 0) {
            // Set the first row of the picker view as an option to select the device default measured power
            return NSLocalizedString("Use Device Default Value", comment:"Description for selecting the device default power, shown on the pickser wheel.  Should be kept concise")

        } else {
            // Construct the a string to return.  Negative values will already be prexied with a minus sign
            let sign = (row < 102 ? "" : "+")
            return "\(sign)\(row - 101)dB"
        }
    }
    
    func numberOfComponentsInPickerView(_: UIPickerView?) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView?, numberOfRowsInComponent component: Int) -> Int {
        // -100dB to +100dB inclusive plus an option to select device default measured power
        return 202
    }
    
    /**************************************************************************************
    *
    *  UITextField Delegate Functions
    *
    **************************************************************************************/
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        
        // Dismiss the keyboard
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldEndEditing(textField: UITextField!) -> Bool {
        
        switch (textField.tag) {
            
        case 1:
            // Replace empty string with a default value
            if (textField.text == "") {
                textField.text = "GemTot iOS"
            }

        case 2...3:
            
            // Validate the major and minor values before accepting.  If invalid, throw an alert and empty the field
            if (textField.text.toInt() > 0xFFFF) {
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
                targetText = self.pickerView(_dbPicker, titleForRow: row, forComponent: 0)
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
    
    func textFieldDidEndEditing(textField: UITextField!) {
        
        // Store the updated values in the config dictionary
        switch (textField.tag) {
            
        case 1:
            _iBeaconConfig.writeValue(textField.text as NSString, forKey:"beaconName", toStore:"iBeacon")
            _iBeaconConfig.writeValue(PKUUID.UUIDforString(textField.text) as NSString, forKey:"UUID", toStore:"iBeacon")
            
        case 2:
            _iBeaconConfig.writeValue(textField.text.toInt()! as NSNumber, forKey: "major", toStore: "iBeacon")
            
        case 3:
            _iBeaconConfig.writeValue(textField.text.toInt()! as NSNumber, forKey: "minor", toStore: "iBeacon")
            
        default:
            break
        }
        
        // If the beacon is broadcasting - dispatch a job to restart the beacon which will pick up the new values
        if (_toggleSwitch.on) {
            dispatch_async(dispatch_get_main_queue(), {var beacon = self._beacon.startBeacon()})
        }
        
        // Dismiss the keyboard
        textField.resignFirstResponder()
    }
    
}