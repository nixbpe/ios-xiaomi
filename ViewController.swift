//
//  ViewController.swift
//  supperproject
//
//  Created by Khakhana Thimachai on 2019-02-06.
//  Copyright © 2019 Khakhana Thimachai. All rights reserved.
//

import UIKit
import CoreBluetooth


class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    @IBOutlet weak var btnUpdate: UIButton!
    @IBOutlet weak var txtView: UITextField!

    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var characteristic: CBCharacteristic!

    let MI_SERVICE_UUID = CBUUID.init(string: "0000fee0")
    let MI_CHARACTERISTIC_COUNT_STEPS_UUID = CBUUID.init(string: "00000007-0000-3512-2118-0009AF100700")

    override func viewDidLoad() {
        super.viewDidLoad()
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
        case .unknown:
            txtView.text? = "unknown"
        case .resetting:
            txtView.text? = "resetting"
        case .unsupported:
            txtView.text? = "unsupported"
        case .unauthorized:
            txtView.text? = "unauthorized"
        case .poweredOff:
            txtView.text? = "poweredOff"
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if (peripheral.state == CBPeripheralState.connected) {
            peripheral.delegate = self
            peripheral.discoverServices([MI_SERVICE_UUID])
        } else {
            // @TODO implement
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
        let steps = parseStepsFromData(data: characteristic.value!);
        txtView.text? = String(steps)
    }

    private func parseStepsFromData(data: Data) -> UInt32 {
        return UInt32((data[1] & 0xFF)) + (UInt32(data[2]) << 8) + (UInt32(data[3]) << 16)
    }

}
