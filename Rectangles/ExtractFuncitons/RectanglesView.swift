import SwiftUI
import Vision

struct RectanglesView: View {
    var image: UIImage
    @State private var invoiceID: String = ""
    @State private var invoiceDates: String = ""
    
    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 300)
            
            if !invoiceID.isEmpty {
                Text("InvoiceID: \(invoiceID)")
                    .font(.headline)
                    .padding(.top)
            }

            if !invoiceDates.isEmpty {
                Text("Issue Dates: \(invoiceDates)")
                    .font(.headline)
                    .padding(.top)
            }
        }
        .onAppear {
            extractData()
        }
    }
    
    func extractData() {
        let invoiceIDs = InvoiceExtractor.extractInvoiceNumber(from: image)
        let issueDates = extractDates(from: image)
        
        if let firstID = invoiceIDs.first {
            invoiceID = "\(firstID) (\(invoiceIDs.dropFirst().joined(separator: ", ")))"
            print("Found Invoice ID: \(invoiceID)")
        }

        if !issueDates.isEmpty {
            invoiceDates = issueDates.joined(separator: "\n")
            print("Found Dates: \(invoiceDates)")
        }
    }
}
