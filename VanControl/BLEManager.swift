import SwiftUI
import CoreBluetooth

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    private var esp32Peripheral: CBPeripheral?
    private var relayCharacteristic: CBCharacteristic?
    
    @Published var isConnected = false
    @Published var relayState = false
    @Published var rssi: Int?  // Variable für die Signalstärke
    
    private var backgroundTimer: Timer?
    
    // UUIDs des ESP32
    let serviceUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
    let characteristicUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        // Beobachten, wann die App in den Hintergrund geht
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    // Scanning starten
    func startScanning() {
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        print("Starte Bluetooth-Scan...")
    }
    
    // Verbindung herstellen
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        esp32Peripheral = peripheral
        esp32Peripheral?.delegate = self
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        peripheral.discoverServices([serviceUUID])
        
        // Startet das periodische Abrufen des RSSI-Werts
        startRSSIUpdates()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        rssi = nil  // Setze RSSI auf nil, wenn die Verbindung getrennt wird
        startScanning()
    }
    
    // Dienst und Charakteristik finden
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services where service.uuid == serviceUUID {
                peripheral.discoverCharacteristics([characteristicUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics where characteristic.uuid == characteristicUUID {
                relayCharacteristic = characteristic
                peripheral.readValue(for: characteristic)  // Leseanforderung für den aktuellen Status
            }
        }
    }
    
    // Wert lesen und den relayState setzen (für Initialstatus des Relais)
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value, let stringValue = String(data: value, encoding: .utf8) {
            relayState = (stringValue == "true")
        }
    }
    
    // Status des Relais schreiben
    func writeRelayState(_ state: Bool) {
        guard let characteristic = relayCharacteristic else {
            return
        }
        let value = state ? "true" : "false"
        if let data = value.data(using: .utf8) {
            esp32Peripheral?.writeValue(data, for: characteristic, type: .withResponse)
        }
    }
    
    // Zentral-Manager-Status überprüfen
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScanning()
        } else {
            isConnected = false
        }
    }
    
    // Funktion, um RSSI regelmäßig abzurufen
    func startRSSIUpdates() {
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            self.esp32Peripheral?.readRSSI()
        }
    }
    
    // RSSI-Wert empfangen
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if error == nil {
            rssi = RSSI.intValue
            print("Aktuelle Signalstärke (RSSI): \(rssi!) dBm") // Ausgabe des dBm-Werts im Debug
        }
    }
    
    // App geht in den Hintergrund
    @objc func appMovedToBackground() {
        print("App im Hintergrund, Timer startet für 30 Sekunden")
        backgroundTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { _ in
            self.disconnect()
        }
    }
    
    // App kommt wieder in den Vordergrund
    @objc func appMovedToForeground() {
        print("App wieder im Vordergrund")
        backgroundTimer?.invalidate()
        backgroundTimer = nil
        if !isConnected {
            startScanning()
        }
    }
    
    // Verbindung trennen
    func disconnect() {
        if let peripheral = esp32Peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
            isConnected = false
            print("Verbindung nach 30 Sekunden im Hintergrund beendet")
        }
    }
}
