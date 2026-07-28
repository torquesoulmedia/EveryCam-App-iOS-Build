import SwiftUI

// UIDocumentPickerViewController im Export-Modus — dokumentierte UIKit-
// Ausnahme (CLAUDE.md §3), analog zu ShareSheet.swift, da SwiftUI keinen
// eigenen Dokumenten-Picker kennt. Kopiert die übergebenen Sammlung-Ordner
// systemseitig an den vom Nutzer gewählten Ort (Dateien-App: Auf diesem
// iPhone, iCloud Drive, oder jeder installierte Drittanbieter wie Google
// Drive/Dropbox) — genau der native Weg, den auch die Dateien-App selbst für
// "Duplizieren nach…" verwendet (Nutzerwunsch: "so wie es das Gerät auch
// systemseitig löst").
//
// asCopy: true lässt die Original-Ordner in der App-Sandbox unangetastet —
// das ist eine zusätzliche Sicherungskopie, kein Verschieben. Das System
// kopiert dabei automatisch rekursiv (Unterordner je Tag, Unsorted,
// collection.json), es ist kein eigener Kopier-Code nötig.
struct CollectionExportPicker: UIViewControllerRepresentable {
    let urls: [URL]

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        UIDocumentPickerViewController(forExporting: urls, asCopy: true)
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
}
