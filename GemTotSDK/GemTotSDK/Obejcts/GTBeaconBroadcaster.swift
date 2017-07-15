//
//  GTBeaconBroadcaster.swift
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
import CoreLocation
import CoreBluetooth

// Constants to hold a singleton instance
let _GlobalGTBeaconBroadcasterSharedInstance = GTBeaconBroadcaster()


class GTBeaconBroadcaster: NSObject, CBPeripheralManagerDelegate {
    
    // Dictionary to hold the beacon config paramaters
    let _beaconConfig : GTStorage = GTStorage.sharedGTStorage
    
    // Shared core bluetooth peripheral manager
    var _peripheralManager : CBPeripheralManager?
    
    // Singleton pattern
    class var sharedGTBeaconBroadcaster:GTBeaconBroadcaster {
        return _GlobalGTBeaconBroadcasterSharedInstance
    }
    
    override init() {
        super.init()
        
        // Init the peripheral manager instance
        _peripheralManager = CBPeripheralManager(delegate: self, queue:DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default))
    }
    
    /**
    *
    *  @brief   Convinience method to start broadcasting an iBeacon signal.
    *           Beacon paramaters are read from the config dictionary
    *
    *  @return  success: Bool, error: NSString?
    *
    */
    
    @discardableResult func startBeacon()  -> (success: Bool, error: NSString?) {
        
        return startBeaconFor(_beaconConfig.getValue("UUID", fromStore:"iBeacon") as! NSString,
            withMajor: _beaconConfig.getValue("major", fromStore:"iBeacon") as! NSNumber,
            withMinor: _beaconConfig.getValue("minor", fromStore:"iBeacon") as! NSNumber,
            withPower: _beaconConfig.getValue("power", fromStore:"iBeacon") as! NSNumber)
    }
    
    /**
    *
    *  @brief   Start broadcasting an iBeacon signal with the paramaters passed to this methog
    *
    *  @param   beaconName - the UUID of the beacon as an NSString. Must be a valid UUID
    *  @param   withMajor - the Major value as an NSNumber. Valid value any unsigned 16 bit integer
    *  @param   withMinor - the Minor value as an NSNumber. Valid value any unsigned 16 bit integer
    *  @param   withPower - the Power value as an NSnumber. Valid value any signed 8 bit integer. A value of 127 will use the device default power
    *
    *  @return  success: Bool, error: NSString?
    *
    */
    
    func startBeaconFor(_ beaconName: NSString, withMajor: NSNumber, withMinor: NSNumber, withPower: NSNumber) -> (success: Bool, error: NSString?) {
        
        // Validate the paramaters
        // Convert the beaconName NSString to a NSUUID
        let beaconUUID: UUID? = UUID(uuidString: beaconName as String)
        
        // If we don't have a valid UUID, return false
        if (nil == beaconUUID) {
            return (false, NSLocalizedString("Invalid UUID", comment:"Message displayed when attempt made to start beacon with an invalid UUID") as NSString)
        }
        
        if (0 > withMajor.intValue || withMajor.intValue > 0xFFFF) {
            return (false, NSLocalizedString("Invalid Major Value", comment:"Message displayed when attempt made to start beacon with an invalid Major Value") as NSString)
        }
        
        if (0 > withMinor.intValue || withMinor.intValue > 0xFFFF) {
            return (false, NSLocalizedString("Invalid Minor Value", comment:"Message displayed when attempt made to start beacon with an invalid Minor Value") as NSString)
        }
        
        if (-128 > withPower.intValue || withPower.intValue > 127) {
            return (false, NSLocalizedString("Invalid Power Value", comment:"Message displayed when attempt made to start beacon with an invalid Power Value") as NSString)
        }
        
        // Check the current state of the pepipheral manager
        var isAdvertising = _peripheralManager!.isAdvertising
        
        // If already advertising, Stop the beacon to flush any previous values
        if (isAdvertising == true) {
            _peripheralManager!.stopAdvertising()
            isAdvertising = false
        }
        
        // Wait for up to a second to retrieve the radio state if the state is unknown
        var i = 0;
        while (i < 1000 && _peripheralManager!.state == .unknown ) {
            Thread.sleep(forTimeInterval: 0.001);
            i += 1;
        }
        // NSLog("Radio took %dms to report state", i);
        
        // If we do not have access to the Bluetooth radio, display an alert in the current view controller
        if(_peripheralManager!.state != .poweredOn) {
            
            let alert = UIAlertController(title: NSLocalizedString("Bluetooth must be available and enabled to configure your device as an iBeacon", comment:"Alert that is shown if Bluetooth is not available"), message: nil, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Okay", comment:"OK button used to dismiss alerts"), style: UIAlertActionStyle.cancel, handler: nil))
            if let topWindow = getTopWindow() {
                topWindow.present(alert, animated: true, completion: nil)
            } else {
                NSLog("topWindow is nil")
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: "iBeaconBroadcastStatus"), object: nil, userInfo: ["broadcastStatus" : false])
            
        } else {
            
            // Set up a beacon region with the UUID, Major and Minor values
            let region = CLBeaconRegion(proximityUUID:beaconUUID!, major:withMajor.uint16Value, minor:withMinor.uint16Value, identifier:"com.gemtots.afr")
            
            // Attempt to set up a peripheral with the measured power
            let peripheralData : NSMutableDictionary? = region.peripheralData(withMeasuredPower: (withPower.intValue == 127) ? nil : withPower)
            
            
            // if we have a peripheral, start advertising
            if (peripheralData != nil) {
                
                // let's first convert NSMutableDicitionary to swift Dictionary
                var swiftDict : Dictionary<String,AnyObject?> = Dictionary<String,AnyObject!>()
                for key in peripheralData!.allKeys {
                    let stringKey = key as! String
                    if let keyValue = peripheralData!.value(forKey: stringKey){
                        swiftDict[stringKey] = keyValue as AnyObject
                    }
                }
                
                _peripheralManager!.startAdvertising(swiftDict)
                
                // update the config dictionary to indicate we are broadcasting
                _beaconConfig.writeValue(true as NSNumber, forKey: "broadcasting", toStore: "iBeacon")
                
                
                return (true, nil)
                
            } else {
                
                // we don't have a valid peripheral so return an error
                return (false, "Peripheral region not be initialised")
            }
        }
        
        return (false, "Bluetooth not available")
    }
    
    /**
    *
    *  @brief   Stop broadcasting an iBeacon signal.
    *
    *  @return  void
    *
    */
    
    func stopBeacon() {
        
        if (_peripheralManager!.isAdvertising) {
            
            // Update config dictionary with broadcasting status
            _beaconConfig.writeValue(false as NSNumber, forKey: "broadcasting", toStore: "iBeacon")
            
            _peripheralManager!.stopAdvertising()
        }
    }
    
    /**
    *
    *  @brief   Report the current state of the beacon
    *
    *  @return  Bool - true if broadcasting an iBeacon signal
    *
    */
    
    func beaconStatus() -> Bool {
        
        return _peripheralManager!.isAdvertising
    }
    
    /**
    *
    *  @brief   Peripheral Manager Delegate
    *
    *  @return  Void
    *
    */
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
        if (peripheral.state == .poweredOn) {
            
            let shouldBroadcast: Bool = (_beaconConfig.getValue("broadcasting", fromStore: "iBeacon") as! NSNumber).boolValue
            
            if (peripheral.isAdvertising != shouldBroadcast) {
                
                let notificationPayload = ["broadcastStatus" : shouldBroadcast]
                
                if (shouldBroadcast == true) {
                    startBeacon()
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "iBeaconBroadcastStatus"), object: nil, userInfo: notificationPayload)
                } else {
                    stopBeacon()
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "iBeaconBroadcastStatus"), object: nil, userInfo: notificationPayload)
                }
            }
        }
    }
    
    /**
    *
    *  @brief   Utility function to get the current view controller
    *           Required to present alerts to the current  view controller
    *
    *  @return  UIViewController ID of the current View Controller
    *
    */
    
    //
    func getTopWindow()->UIViewController? {
        
        var topViewController : UIViewController? = UIApplication.shared.keyWindow?.rootViewController
        
        while (topViewController?.presentedViewController != nil) {
            topViewController = topViewController?.presentedViewController
        }
        
        return topViewController
    }
}
