import UIKit
import Vision

func extractDates(from image: UIImage) -> [String: String] {
    var dateCandidates = [String: String]()
    
    let request = VNRecognizeTextRequest { (request, error) in
        guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
            print("Error recognizing text: \(String(describing: error))")
            return
        }
        
        // Define label keywords and an empty dictionary for storing the closest date to each label
        let labelKeywords = ["Invoice Date", "Due Date", "Tax Point Date", "Delivery Date"]
        var labelPositions = [String: CGRect]()
        var datePositions = [(String, CGRect)]()

        // Refined Regular expression patterns for date formats, including text month formats
        let datePatterns = [
            // Numeric dates
            "\\b\\d{2}[\\./-]\\d{2}[\\./-]\\d{4}\\b", // DD-MM-YYYY, DD/MM/YYYY, DD.MM.YYYY
            "\\b\\d{2}[\\./-]\\d{2}[\\./-]\\d{2}\\b", // DD-MM-YY, DD/MM/YY, DD.MM.YY
            "\\b\\d{4}[\\./-]\\d{2}[\\./-]\\d{2}\\b", // YYYY-MM-DD, YYYY/MM/DD, YYYY.MM.DD
            "\\b\\d{2}[\\./-]\\d{4}\\b",             // MM-YYYY, MM/YYYY, MM.YYYY
            "\\b\\d{2}[\\./-]\\d{2}\\b",             // DD-MM, DD/MM, DD.MM
            "\\b\\d{4}\\b",                          // YYYY

            // Month names with dates (including text month formats)
            "\\b\\d{2}\\s+[A-Za-z]+\\s+\\d{4}\\b",   // DD MMMM YYYY, DD MMM YYYY
            "\\b[A-Za-z]+\\s+\\d{2},\\s+\\d{4}\\b",  // MMMM DD, YYYY, MMM DD, YYYY
            "\\b\\d{4}\\s+[A-Za-z]+\\s+\\d{2}\\b",   // YYYY MMMM DD, YYYY MMM DD
            "\\b[A-Za-z]+\\s+\\d{4}\\b",             // MMMM YYYY, MMM YYYY
            
            // Additional formats with text month
            "\\b\\d{2}-[A-Za-z]{3}-\\d{4}\\b",       // DD-MMM-YYYY
            "\\b\\d{2}/[A-Za-z]{3}/\\d{4}\\b",       // DD/MMM/YYYY
            "\\b\\d{2}(?:st|nd|rd|th)?\\s+[A-Za-z]+\\s+\\d{4}\\b", // DDth MMMM YYYY, DDth MMM YYYY
            "\\b\\d{4}\\s+[A-Za-z]+\\s+\\d{2}\\b",   // YYYY MMMM DD, YYYY MMM DD
        ]

        // First pass: Identify label positions
        for observation in observations {
            let text = observation.topCandidates(1).first?.string ?? ""
            for label in labelKeywords {
                if text.lowercased().contains(label.lowercased()) {
                    labelPositions[label] = observation.boundingBox
                    break
                }
            }
        }

        // Second pass: Identify date positions
        for observation in observations {
            let text = observation.topCandidates(1).first?.string ?? ""
            for pattern in datePatterns {
                let regex = try! NSRegularExpression(pattern: pattern)
                let range = NSRange(location: 0, length: text.utf16.count)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    let matchedString = (text as NSString).substring(with: match.range)
                    // Validate the matched string as a date
                    if isLikelyDate(matchedString) {
                        datePositions.append((matchedString, observation.boundingBox))
                    }
                }
            }
        }

        // Assign dates to labels based on proximity
        for (label, labelBox) in labelPositions {
            var closestDate: (String, CGRect)?
            var minDistance = CGFloat.greatestFiniteMagnitude
            
            for (date, dateBox) in datePositions {
                let distance = abs(labelBox.minY - dateBox.minY) + abs(labelBox.minX - dateBox.minX)
                if distance < minDistance {
                    closestDate = (date, dateBox)
                    minDistance = distance
                }
            }
            
            if let closestDate = closestDate {
                dateCandidates[label] = closestDate.0
                // Remove the assigned date to prevent it from being reused
                datePositions.removeAll { $0 == closestDate }
            }
        }
    }

    guard let cgImage = image.cgImage else {
        print("Error: Could not get CGImage from UIImage")
        return dateCandidates
    }

    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
        try requestHandler.perform([request])
    } catch {
        print("Error performing text recognition: \(error)")
    }

    return dateCandidates
}

func isLikelyDate(_ text: String) -> Bool {
    let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
    if let match = detector?.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
        return match.range.length == text.utf16.count
    } else {
        return false
    }
}
