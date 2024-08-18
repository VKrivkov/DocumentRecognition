import UIKit
import Vision

func extractDates(from image: UIImage) -> [String] {
    var datesSet = Set<Date>()
    
    let request = VNRecognizeTextRequest { (request, error) in
        guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
            print("Error recognizing text: \(String(describing: error))")
            return
        }

        // Initialize NSDataDetector for date detection
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        
        for observation in observations {
            let text = observation.topCandidates(1).first?.string ?? ""
            print("Raw OCR Text: \(text)")  // Log the recognized text for debugging
            
            // Use NSDataDetector to find dates in the recognized text
            let range = NSRange(location: 0, length: text.utf16.count)
            detector?.enumerateMatches(in: text, options: [], range: range) { (match, _, _) in
                if let date = match?.date {
                    datesSet.insert(date) // Automatically handles duplicates
                }
            }
        }
    }

    guard let cgImage = image.cgImage else {
        print("Error: Could not get CGImage from UIImage")
        return []
    }

    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
        try requestHandler.perform([request])
    } catch {
        print("Error performing text recognition: \(error)")
    }

    // Convert the Set to an Array and sort dates in increasing order
    let sortedDates = datesSet.sorted()

    // Format dates to "YYYY-MM-DD"
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    let formattedDates = sortedDates.map { dateFormatter.string(from: $0) }
    
    return formattedDates
}
