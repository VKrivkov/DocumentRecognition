import SwiftUI
import Vision
import UIKit

struct RectanglesView: View {
    var image: UIImage
    @State private var recognizedImage: UIImage?
    @State private var recognizedTexts: [String] = []
    @State private var combinedText: String = ""

    var body: some View {
        ScrollView {
            VStack {
                if let recognizedImage = recognizedImage {
                    Image(uiImage: recognizedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .onAppear {
                            recognizeText(in: image)
                        }
                }
                
                List(recognizedTexts.indices, id: \.self) { index in
                    Text("Box \(index + 1): \(recognizedTexts[index])")
                        .contextMenu {
                            Button(action: {
                                UIPasteboard.general.string = recognizedTexts[index]
                            }) {
                                Text("Copy")
                                Image(systemName: "doc.on.doc")
                            }
                        }
                }
                .frame(height: 300) // Adjust height as needed
                
                Text("Combined Text:")
                    .font(.headline)
                    .padding(.top)
                
                TextEditor(text: $combinedText)
                    .frame(height: 200) // Adjust height as needed
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    .padding()
            }
        }
    }

    func recognizeText(in image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                print("Error recognizing text: \(String(describing: error))")
                return
            }

            DispatchQueue.main.async {
                let mergedBoxes = mergeCloseBoundingBoxes(observations: observations, in: image)
                let drawnImage = drawRectangles(for: mergedBoxes, in: image)
                self.recognizedImage = drawnImage
                self.recognizedTexts = extractTexts(from: mergedBoxes, in: image, using: observations)
                self.combinedText = self.recognizedTexts.joined(separator: "\n")

                // Print coordinates of text bounding boxes and their text
                for (index, box) in mergedBoxes.enumerated() {
                    let x = box.origin.x * image.size.width
                    let y = (1 - box.origin.y - box.size.height) * image.size.height
                    let width = box.size.width * image.size.width
                    let height = box.size.height * image.size.height
                    print("Box \(index + 1): x: \(x), y: \(y), width: \(width), height: \(height)")
                    print("Text: \(self.recognizedTexts[index])\n")
                }
            }
        }
        request.recognitionLevel = .accurate

        do {
            try requestHandler.perform([request])
        } catch {
            print("Error performing text recognition: \(error)")
        }
    }

    func mergeCloseBoundingBoxes(observations: [VNRecognizedTextObservation], in image: UIImage) -> [CGRect] {
        var mergedBoxes = [CGRect]()

        for observation in observations {
            let newBox = observation.boundingBox

            var didMerge = false
            for (index, box) in mergedBoxes.enumerated() {
                if shouldMerge(box1: box, box2: newBox, in: image) {
                    mergedBoxes[index] = box.union(newBox)
                    didMerge = true
                    break
                }
            }

            if !didMerge {
                mergedBoxes.append(newBox)
            }
        }

        return mergedBoxes
    }

    func shouldMerge(box1: CGRect, box2: CGRect, in image: UIImage) -> Bool {
        let threshold: CGFloat = 0.016 // smaller threshold

        let box1Adjusted = CGRect(x: box1.origin.x * image.size.width, y: box1.origin.y * image.size.height, width: box1.size.width * image.size.width, height: box1.size.height * image.size.height)
        let box2Adjusted = CGRect(x: box2.origin.x * image.size.width, y: box2.origin.y * image.size.height, width: box2.size.width * image.size.width, height: box2.size.height * image.size.height)

        let isCloseVertically = abs(box1Adjusted.maxY - box2Adjusted.minY) < threshold * image.size.height || abs(box2Adjusted.maxY - box1Adjusted.minY) < threshold * image.size.height

        let isSameColumn = abs(box1Adjusted.minX - box2Adjusted.minX) < threshold * image.size.width || abs(box1Adjusted.maxX - box2Adjusted.maxX) < threshold * image.size.width

        return isCloseVertically && isSameColumn
    }

    func drawRectangles(for mergedBoxes: [CGRect], in image: UIImage) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, false, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else { return image }
        image.draw(at: CGPoint.zero)

        context.setStrokeColor(UIColor.red.cgColor)
        context.setLineWidth(2.0)

        for box in mergedBoxes {
            let x = box.origin.x * image.size.width
            let y = (1 - box.origin.y - box.size.height) * image.size.height
            let width = box.size.width * image.size.width
            let height = box.size.height * image.size.height

            context.stroke(CGRect(x: x, y: y, width: width, height: height))
        }

        let drawnImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return drawnImage ?? image
    }

    func extractTexts(from mergedBoxes: [CGRect], in image: UIImage, using observations: [VNRecognizedTextObservation]) -> [String] {
        var extractedTexts = [String]()
        
        for box in mergedBoxes {
            let boxText = observations.filter { observation in
                let rect = observation.boundingBox
                return rect.intersects(box)
            }
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: " ")
            
            extractedTexts.append(boxText)
        }
        
        return extractedTexts
    }
}
