//
// Created by Khakhana Thimachai on 2019-02-11.
// Copyright (c) 2019 ___FULLUSERNAME___. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit

class MiBand: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var characteristic: CBCharacteristic!
    var steps = -1

    let alert = UIAlertController(title: "DEBUG MIBAND", message: "This is an alert.", preferredStyle: .alert)

    let MI_SERVICE_UUID = CBUUID.init(string: "0000fee0")
    let MI_CHARACTERISTIC_COUNT_STEPS_UUID = CBUUID.init(string: "00000007-0000-3512-2118-0009AF100700")

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
        case .poweredOn:
            // ค้นหา peripheral ที่เป็น Mi Band ที่เชื่อมต่อแล้ว (ผ่าน Mi Fit)
            let peripheralMi = centralManager.retrieveConnectedPeripherals(withServices: [MI_SERVICE_UUID]).first!
            // บันทึกค่า peripheral ที่เจอเก็บไว้สำหรับใช้งาน
            self.peripheral = peripheralMi
            // ทำการเชื่อมต่อ Central Manager กับ peripheral
            centralManager.connect(peripheralMi, options: nil)
        default:
            print(central.state.rawValue)
            // TODO Implement alert
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if (peripheral.state == CBPeripheralState.connected) {
            peripheral.delegate = self
            peripheral.discoverServices([MI_SERVICE_UUID])
        } else {
            // TODO : implement alert
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                /**
                * ตรวจสอบว่ามีค่า UUID สำหรับเรียกดูข้อมูล Mi Band 3 และเมื่อทำการ subscribe ข้อมูลสำหรับการนับก้าว
                **/
                if (characteristic.uuid.uuidString == MI_CHARACTERISTIC_COUNT_STEPS_UUID.uuidString) {
                    self.characteristic = characteristic
                    peripheral.setNotifyValue(true, for: self.characteristic)
                    peripheral.readValue(for: self.characteristic)
                }
            }
        } else {
            // @TODO แจ้งเตือนถ้าไม่พบ services
        }
    }

    /**
     * ฟังก์ชัน callback เมื่อมีการอัพเดตค่าการนับก้าวจาก Mi Band 3
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        self.steps = parseStepsFromData(data: characteristic.value!);
    }

    func parseStepsFromData(data: Data) -> Int {
        return Int((data[1] & 0xFF)) + (Int(data[2]) << 8) + (Int(data[3]) << 16)
    }

}

