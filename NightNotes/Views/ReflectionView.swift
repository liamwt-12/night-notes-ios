import SwiftUI

struct ReflectionView: View {
    @Environment(\.dismiss) var dismiss
    let dreamContent: String
    let interpretation: String
    let mode: InterpretationMode
    
    var body: some View {
        ZStack {
            VeilBackground()
            ScrollView {
                VStack(alignment: .leading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left").font(.system(size: 12))
                            Text("Return")
                        }.font(Theme.captionFont).foregroundColor(Theme.textSecondary)
                    }.padding(.top, 20)
                    
                    Text(""\(dreamContent)"")
                        .font(Theme.bodySerifFont.italic()).foregroundColor(Theme.textSecondary)
                        .lineSpacing(6).padding(.top, 40).padding(.bottom, 40)
                    
                    Divider().padding(.bottom, 40)
                    
                    Text((mode == .surface ? "Surface" : "Beneath") + " reading".uppercased())
                        .font(Theme.captionFont).foregroundColor(Theme.textMuted).tracking(2).padding(.bottom, 20)
                    
                    Text(interpretation)
                        .font(Font.system(size: 19, design: .serif)).foregroundColor(Theme.textPrimary).lineSpacing(10)
                    
                    HStack(spacing: 12) {
                        ForEach(["Save", "Share", "Go deeper"], id: \.self) { title in
                            Button(title) { dismiss() }
                                .font(Theme.captionFont).foregroundColor(Theme.textSecondary)
                                .padding(.horizontal, 20).padding(.vertical, 16)
                                .background(Color.white.opacity(0.6)).cornerRadius(16)
                        }
                    }.padding(.top, 32)
                    
                    Spacer(minLength: 60)
                }.padding(.horizontal, 32)
            }
        }
    }
}
