import SwiftUI
import UIKit
import UniformTypeIdentifiers
import PDFKit

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var pdfImage: UIImage?
    @Binding var isImagePickerPresented: Bool
    @Binding var isDocumentPickerPresented: Bool
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIDocumentPickerDelegate {
        var parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        // Image Picker Delegate Methods
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.isImagePickerPresented = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isImagePickerPresented = false
        }
        
        // Document Picker Delegate Methods
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            if let document = PDFDocument(url: url), let page = document.page(at: 0) {
                let pdfImage = page.thumbnail(of: CGSize(width: 300, height: 300), for: .mediaBox)
                parent.pdfImage = pdfImage
            }
            parent.isDocumentPickerPresented = false
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.isDocumentPickerPresented = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let picker = UIViewController()
        
        if isImagePickerPresented {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = context.coordinator
            imagePicker.sourceType = .photoLibrary
            picker.present(imagePicker, animated: true)
        } else if isDocumentPickerPresented {
            let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
            documentPicker.delegate = context.coordinator
            picker.present(documentPicker, animated: true)
        }
        
        return picker
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
