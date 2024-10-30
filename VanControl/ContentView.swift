import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @ObservedObject var bleManager = BLEManager()

    var body: some View {
        VStack(spacing: 30) {
            // Titel
            Text("VanControl")
                .font(.title2)
                .bold()
                .padding(.top, 40)
                .padding(.bottom, 40)

            // Verbindung Status und Signalstärke
            HStack(spacing: 50) {
                Text(bleManager.isConnected ? "Verbunden" : "Nicht verbunden")
                    .foregroundColor(bleManager.isConnected ? .green : .red)
                    .font(.headline)
                
                SignalStrengthView(rssi: bleManager.rssi)
                    .frame(width: 50, height: 15) // Kleinere Größe der Balkenanzeige
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity) // Nimmt die gesamte Breite ein
            .multilineTextAlignment(.center) // Zentrierter Text
            
            // Ein-/Aus-Schalter für das Relais
            Toggle("Light Bar Rechts", isOn: $bleManager.relayState)
                .disabled(!bleManager.isConnected)
                .onChange(of: bleManager.relayState) { newValue in
                    bleManager.writeRelayState(newValue)
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
                .font(.title3)

            Spacer()
        }
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all)) // Hintergrundfarbe für den gesamten Bildschirm
        .foregroundColor(.white) // Textfarbe auf weiß für bessere Lesbarkeit
    }
}
