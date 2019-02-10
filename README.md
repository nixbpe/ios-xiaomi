`ตัวอย่างทั้งหมดดูในจากไฟล์ ViewController.swift`

# การเชื่อมต่อ Mi Band 3 เพื่อเรียกค่านับก้าวผ่าน BLE บน iOS โดยใช้ CoreBluetooth

### สิ่งที่จำเป็นต้องมี

**ทำการเชื่อมต่อ Mi Fit และอุปกรณ์ Mi Band3 รายละเอียดตามลิงก์ https://www.gadgeteer.in.th/review/how-to-use-mi-band-3/**



### ขั้นตอนการเขียนโปรแกรมสำหรับดึงข้อมูลจำนวนก้าวโดยใช้ CoreBluetooth

1. ทำการ `import CoreBluetooth` และ extentds `CBCentralManagerDelegate, CBPeripheralDelegate` สำหรับ class ที่จะใช้งาน

   ```swift
   import UIKit
   import CoreBluetooth
   
   class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
       // ...
   }
   ```

   

2. ประการศตัวแปรที่จำเป็นสำหรับการใช้งาน

3. ```swift
   var centralManager: CBCentralManager!
   var peripheral: CBPeripheral!
   var characteristic: CBCharacteristic!
   
   let MI_SERVICE_UUID = CBUUID.init(string: "0000fee0")
   let MI_CHARACTERISTIC_COUNT_STEPS_UUID = CBUUID.init(string: "00000007-0000-3512-2118-0009AF100700")
   
   ```



3. สร้าง Central Manager และเริ่มการทำงานของของ Bluetooth

   ```swift
   override func viewDidLoad() {
       super.viewDidLoad()
       centralManager = CBCentralManager(delegate: self, queue: nil)
   }
   ```

4. ทำการ implement `func centralManagerDidUpdateState(_ central: CBCentralManager)` from `CBCentralManagerDelegate` เพื่อให้เครื่องทำการเชื่อมต่อกับ device เมื่อ bluetooth อยู่ที่สถานะ `poweredOn`

   ```swift
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
           // 
       case .resetting:
           //
       case .unsupported:
           //
       case .unauthorized:
           // 
       case .poweredOff:
   		//
       }
   }
   ```

5. ทำการ implement `func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)` เพื่อค้นหา service ที่สามารถใช้งานได้หลังจากเชื่อมต่อสำเร็จ

   ```swift
   func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
           if (peripheral.state == CBPeripheralState.connected) {
               peripheral.delegate = self
               peripheral.discoverServices([MI_SERVICE_UUID])
           } else {
               // @TODO implement
           }
       }
   ```

6. ทำการ imeplement ฟังก์ชันที่จำเป็นสำหรับการอ่านข้อมูลการนับก้าวจาก Mi Band 3 โดยค่ากานับก้าวจะถูกเรียก callback จาก `func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)`

   ```swift
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
   ```
