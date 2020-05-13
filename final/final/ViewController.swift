
import UIKit
import CoreBluetooth


let rowerServiceCBUUID = CBUUID(string: "CE060000-43E5-11E4-916C-0800200C9A66")
let characteristic1CBUUID = CBUUID(string: "CE060031-43E5-11E4-916C-0800200C9A66")
let characteristic2CBUUID = CBUUID(string: "2AD1")
class HRMViewController: UIViewController {
    @IBOutlet weak var heartRateLabel: UILabel!
    @IBOutlet weak var bodySensorLocationLabel: UILabel!
    var centralManager: CBCentralManager!
    var pmPeripheral: CBPeripheral!
    var wattValue: Int!
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        // Make the digits monospaces to avoid shifting when the numbers change
        heartRateLabel.font = UIFont.monospacedDigitSystemFont(ofSize: heartRateLabel.font!.pointSize, weight: .regular)
    }
    
    func onHeartRateReceived(_ heartRate: Int) {
        heartRateLabel.text = String(heartRate)
        print("BPM: \(heartRate)")
    }
}
extension HRMViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central state update")
        if central.state != .poweredOn {
            print("Central is not powered on")
        } else {
            print("Central scanning for", rowerServiceCBUUID);
            centralManager.scanForPeripherals(withServices: [rowerServiceCBUUID],
                                              options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        Swift.print(peripheral)
        peripheral.delegate = self
        pmPeripheral = peripheral
        pmPeripheral.delegate = self
        centralManager.stopScan()
        centralManager.connect(pmPeripheral!)
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Swift.print("Connected!")
        pmPeripheral.discoverServices(nil)
    }
    
}
extension HRMViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            Swift.print(service)
            Swift.print(service.characteristics ?? "characteristics are nil")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?){
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            Swift.print(characteristic)
            if characteristic.properties.contains(.read) {
                Swift.print("\(characteristic.uuid): properties contains .read")
            }
            if characteristic.properties.contains(.notify) {
                Swift.print("\(characteristic.uuid): properties contains .notify")
            }
            peripheral.readValue(for: characteristic)
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        switch characteristic.uuid {
        case characteristic1CBUUID: break
        default:
            Swift.print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    func onRowingGeneralStatusUpdate(characteristic: CBCharacteristic) {
        guard let data = characteristic.value else { return }
        
        // elapsed time in sec
        let elapsedTime: Double = Double(Int(data[0]) + 256 * Int(data[1]) + 65536 * Int(data[2])) / 100.0
        // distance in m
        let distance: Double = Double(Int(data[3]) + 256 * Int(data[4]) + 65536 * Int(data[5])) / 10.0
        //Workout Type
        let workout: String =  workoutType(for: data[6])
        print(workout)
    }
    
    func workoutType(for code: UInt8) -> String {
        switch code {
        case 0:
            return "Just row, no splits"
        case 1:
            return "Just row, splits"
        case 2:
            return "Fixed dist, no splits"
        case 3:
            return "Fixed dist, splits"
        case 4:
            return "Fixed time, no splits"
        case 5:
            return "Fixed time, splits"
        case 6:
            return "Fixed time, interval"
        case 7:
            return "Fixed dist, interval"
        case 8:
            return "Variable, interval"
        case 9:
            return "Variable, undef rest, interval"
        case 10:
            return "Fixed, calorie"
        case 11:
            return "Fixed, watt-minutes"
        case 12:
            return "Fixed cals, interval"
        default:
            return "Error"
        }
    }
}
