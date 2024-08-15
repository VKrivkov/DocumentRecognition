import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var pdfImage: UIImage?
    @Binding var isImagePickerPresented: Bool
    @Binding var isDocumentPickerPresented: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        if isImagePickerPresented {
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            return picker
        } else if isDocumentPickerPresented {
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
            picker.delegate = context.coordinator
            return picker
        }
        return UIViewController() // Default case
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let selectedImage = info[.originalImage] as? UIImage {
                parent.image = selectedImage
            }
            parent.isImagePickerPresented = false
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first, let pdfData = try? Data(contentsOf: url), let pdfImage = UIImage(data: pdfData) {
                parent.pdfImage = pdfImage
            }
            parent.isDocumentPickerPresented = false
        }
    }
}
