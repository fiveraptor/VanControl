import SwiftUI

struct SignalStrengthView: View {
    var rssi: Int?

    // Funktion zur Bestimmung der Farbe basierend auf dem RSSI-Wert
    func colorForSignalStrength() -> Color {
        guard let rssi = rssi else { return Color.gray } // Keine Verbindung oder kein RSSI

        switch rssi {
        case -100 ... -80:
            return Color.red // Sehr schwach
        case -80 ..< -60:
            return Color.orange // Schwach
        case -60 ..< -40:
            return Color.yellow // Mittel
        case -40 ..< -20:
            return Color.green // Gut
        case -20 ... 0:
            return Color.green.opacity(0.8) // Sehr gut
        default:
            return Color.gray
        }
    }

    // Funktion zur Bestimmung der Sichtbarkeit der Balken basierend auf dem RSSI-Wert
    func barsVisible() -> [Bool] {
        guard let rssi = rssi else { return [false, false, false, false] } // Keine Verbindung oder kein RSSI

        switch rssi {
        case -100 ... -80:
            return [true, false, false, false] // Nur der erste Balken sichtbar
        case -80 ..< -60:
            return [true, true, false, false] // Die ersten zwei Balken sichtbar
        case -60 ..< -40:
            return [true, true, true, false] // Die ersten drei Balken sichtbar
        case -40 ... 0:
            return [true, true, true, true] // Alle Balken sichtbar
        default:
            return [false, false, false, false] // Alle Balken ausblenden
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<4) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(self.colorForSignalStrength())
                    .frame(width: 10, height: CGFloat(10 + (index * 10))) // Unterschiedliche Höhen für jeden Balken
                    .opacity(self.barsVisible()[index] ? 1.0 : 0.2) // Sichtbarkeit basierend auf barsVisible
            }
        }
    }
}
