import SwiftUI

struct TireWearView: View {
    @StateObject var inventory = TireWearManager()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                // HEADER
                HStack {
                    Text("TIRE WEAR")
                        .font(.system(size: 28, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "shoe.2.fill")
                        .foregroundColor(.gray)
                }
                .padding(.top)
                .padding(.horizontal)
                
                // INVENTORY LIST
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(inventory.activeTires) { tire in
                            TireCard(tire: tire)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Hardware")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// THE INDIVIDUAL TIRE DISPLAY
struct TireCard: View {
    let tire: Tire
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(tire.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(tire.compound)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(5)
                    .background(tire.compoundColor.opacity(0.2))
                    .foregroundColor(tire.compoundColor)
                    .cornerRadius(5)
            }
            
            // THE TIRE WEAR PROGRESS BAR
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background Track
                    Rectangle()
                        .frame(width: geometry.size.width, height: 10)
                        .opacity(0.3)
                        .foregroundColor(.gray)
                        .cornerRadius(5)
                    
                    // The Wear Indicator (Turns red if over 80% worn)
                    Rectangle()
                        .frame(width: geometry.size.width * CGFloat(tire.wearPercentage), height: 10)
                        .foregroundColor(tire.wearPercentage > 0.8 ? .red : .green)
                        .cornerRadius(5)
                }
            }
            .frame(height: 10)
            
            HStack {
                Text("WEAR: \(Int(tire.wearPercentage * 100))%")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("\(tire.currentMileage, specifier: "%.1f") / \(tire.maxMileage, specifier: "%.0f") KM")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color(white: 0.15))
        .cornerRadius(12)
    }
}
