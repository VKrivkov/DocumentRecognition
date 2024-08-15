import UIKit
import Vision
import NaturalLanguage

func extractIssueDate(from image: UIImage) -> [String] {
    var issueDateCandidates = [String]()
    let request = VNRecognizeTextRequest { (request, error) in
        guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
            print("Error recognizing text: \(String(describing: error))")
            return
        }

        let regex = try! NSRegularExpression(pattern: "\\b\\d{2}[\\./-]\\d{2}[\\./-]\\d{4}\\b")

        for observation in observations {
            let topCandidate = observation.topCandidates(1).first?.string ?? ""
            let range = NSRange(location: 0, length: topCandidate.utf16.count)
            if regex.firstMatch(in: topCandidate, options: [], range: range) != nil {
                if isLikelyDate(topCandidate) {
                    issueDateCandidates.append(topCandidate)
                }
            }
        }
    }

    guard let cgImage = image.cgImage else {
        print("Error: Could not get CGImage from UIImage")
        return issueDateCandidates
    }

    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
        try requestHandler.perform([request])
    } catch {
        print("Error performing text recognition: \(error)")
    }

    return issueDateCandidates
}

func isLikelyDate(_ text: String) -> Bool {
    let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
    if let match = detector?.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
        return match.range.length == text.utf16.count
    } else {
        return false
    }
}
