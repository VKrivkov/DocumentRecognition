import SwiftUI

struct ContentView: View {
    @State private var image: UIImage?
    @State private var pdfImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var isDocumentPickerPresented = false

    var body: some View {
        VStack {
            if let image = image {
                RectanglesView(image: image)
                    .frame(maxWidth: .infinity, maxHeight: 300)
            } else if let pdfImage = pdfImage {
                RectanglesView(image: pdfImage)
                    .frame(maxWidth: .infinity, maxHeight: 300)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .foregroundColor(.gray)
            }
            HStack {
                Button("Choose Photo") {
                    isImagePickerPresented = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                Button("Choose PDF") {
                    isDocumentPickerPresented = true
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(image: $image, pdfImage: $pdfImage, isImagePickerPresented: $isImagePickerPresented, isDocumentPickerPresented: $isDocumentPickerPresented)
        }
        .sheet(isPresented: $isDocumentPickerPresented) {
            ImagePicker(image: $image, pdfImage: $pdfImage, isImagePickerPresented: $isImagePickerPresented, isDocumentPickerPresented: $isDocumentPickerPresented)
        }
    }
}

#Preview {
    ContentView()
}
