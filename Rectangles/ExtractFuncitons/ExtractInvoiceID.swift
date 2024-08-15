import UIKit
import CoreGraphics
import Vision

struct InvoiceExtractor {

    static func extractInvoiceNumber(from image: UIImage) -> [String] {
        var invoiceNumberCandidates = [(candidate: String, score: Int, boundingBox: CGRect)]()
        var invoiceBoundingBox: CGRect?
        var finalScoredCandidates = [(candidate: String, score: Int)]()
        
        // Simplified regex to match only letters, numbers, and allowed special characters
        let regex = try! NSRegularExpression(pattern: "^[A-Za-z0-9-/\\\\]+$", options: .caseInsensitive)
        
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                print("Error recognizing text: \(String(describing: error))")
                return
            }
            
            // Scan for the word "Invoice" and store its coordinates
            for observation in observations {
                if let text = observation.topCandidates(1).first?.string.lowercased(), text.contains("invoice") {
                    if invoiceBoundingBox == nil { // Only take the first occurrence
                        invoiceBoundingBox = observation.boundingBox
                    }
                }
            }
            
            // Print all recognized text and check candidates
            print("All Recognized Text:")
            for observation in observations {
                if let topCandidate = observation.topCandidates(1).first?.string {
                    print(topCandidate)
                    
                    // Split the sentence into words
                    let words = topCandidate.split(separator: " ").map { String($0) }
                    
                    // Check each word against the regex
                    for word in words {
                        if regex.matches(in: word, options: [], range: NSRange(location: 0, length: word.utf16.count)).count > 0 {
                            let score = 0
                            
                            // Store the candidate with its bounding box
                            invoiceNumberCandidates.append((word, score, observation.boundingBox))
                        }
                    }
                }
            }
            
            print("Regex-Valid Candidates:")
            print(invoiceNumberCandidates.map { $0.candidate })
            
            // Filter and score candidates
            for (candidate, initialScore, boundingBox) in invoiceNumberCandidates {
                var score = initialScore
                
                // Elevate score if candidate is near "Invoice"
                if let invoiceBox = invoiceBoundingBox, isCloseToInvoice(candidateBox: boundingBox, invoiceBox: invoiceBox, word: candidate) {
                    score += 10  // Strong boost for proximity
                }
                
                // Filter out words, dates, special-character-only, and apply further scoring
                if !isWord(candidate), !isDate(candidate), !isSpecialCharacter(candidate) {
                    if candidate == candidate.uppercased() {
                        score += 1
                    }
                    if candidate.rangeOfCharacter(from: .letters) != nil && candidate.rangeOfCharacter(from: .decimalDigits) != nil {
                        score += 1
                    }
                    if candidate.rangeOfCharacter(from: CharacterSet(charactersIn: "-/\\#")) != nil {
                        score += 1
                    }
                    finalScoredCandidates.append((candidate, score))
                }
            }
            
            // Sort candidates by score
            finalScoredCandidates.sort { $0.score > $1.score }
            
            print("Scored Candidates:")
            for candidate in finalScoredCandidates {
                print("\(candidate.candidate) - Score: \(candidate.score)")
            }
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        do {
            try requestHandler.perform([request])
        } catch {
            print("Error performing text recognition: \(error)")
        }
        
        // Return just the candidates' strings after scoring and sorting
        return finalScoredCandidates.map { $0.candidate }
    }

    // Function to check if a string consists only of letters
    static func isWord(_ text: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: "^[A-Za-z]+$", options: .caseInsensitive)
        return regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)).count > 0
    }

    // Function to check if a string is in a date format
    static func isDate(_ text: String) -> Bool {
        let dateFormats = [
            "^\\d{2}[-/]\\d{2}[-/]\\d{2}$", // DD-MM-YY or DD/MM/YY
            "^\\d{4}[-/]\\d{2}[-/]\\d{2}$", // YYYY-MM-DD or YYYY/MM/DD
            "^\\d{2}[-/]\\d{2}[-/]\\d{4}$"  // DD-MM-YYYY or DD/MM/YYYY
        ]
        
        for format in dateFormats {
            let regex = try! NSRegularExpression(pattern: format, options: .caseInsensitive)
            if regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)).count > 0 {
                return true
            }
        }
        return false
    }

    // Function to check if a string consists only of special characters
    static func isSpecialCharacter(_ text: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: "^[\\-/\\\\]+$", options: .caseInsensitive)
        return regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)).count > 0
    }


    // Helper function to check proximity to the word "INVOICE"
    static func isCloseToInvoice(candidateBox: CGRect, invoiceBox: CGRect, word: String) -> Bool {
        // Define the bounding box for the proximity check
        let proximityBox = CGRect(
            x: invoiceBox.minX, // Start from the left side of "Invoice"
            y: invoiceBox.minY, // Start from the top side of "Invoice"
            width: invoiceBox.width * 3, // Extend the width by a certain multiplier (adjust as needed)
            height: invoiceBox.height * 5 // Extend the height by a certain multiplier (adjust as needed)
        )
        
        // Check if the candidate's bounding box intersects with the proximity box
        let isClose = proximityBox.intersects(candidateBox)
        
        // Debug output to understand why candidates are considered "close"
        if isClose {
            print("Candidate \(word), \(candidateBox) IS considered close to 'Invoice' located at \(invoiceBox)")
        } else {
            print("Candidate \(word), \(candidateBox) is NOT considered close to 'Invoice' located at \(invoiceBox)")
        }
        
        return isClose
    }

}
