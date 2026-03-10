import SwiftUI

struct JournalView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @State private var selectedDream: Dream?
    
    var body: some View {
        ZStack {
            VeilBackground()
            VStack(alignment: .leading) {
                Text("night notes").font(Theme.logoFont).foregroundColor(Theme.textSecondary).tracking(4)
                    .padding(.horizontal, 32).padding(.top, 20)
                
                Text("Your dreams").font(Theme.headingFont).foregroundColor(Theme.textPrimary)
                    .padding(.horizontal, 32).padding(.top, 40)
                
                Text("\(dreamStore.dreamCount) dreams").font(Theme.captionFont).foregroundColor(Theme.textMuted)
                    .padding(.horizontal, 32).padding(.top, 8)
                
                if dreamStore.dreams.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "moon.zzz").font(.system(size: 48)).foregroundColor(Theme.textMuted.opacity(0.5))
                        Text("No dreams yet").font(Theme.bodySerifFont.italic()).foregroundColor(Theme.textMuted)
                    }.frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading) {
                            ForEach(dreamStore.groupedDreams) { group in
                                Text(group.month.uppercased())
                                    .font(Theme.captionFont).foregroundColor(Theme.textMuted).tracking(1.5)
                                    .padding(.horizontal, 32).padding(.top, 28).padding(.bottom, 16)
                                
                                ForEach(group.dreams) { dream in
                                    DreamCard(dream: dream)
                                        .padding(.horizontal, 32).padding(.bottom, 14)
                                        .onTapGesture { selectedDream = dream }
                                }
                            }
                        }.padding(.bottom, 100)
                    }
                }
            }
        }
        .sheet(item: $selectedDream) { dream in DreamDetailView(dream: dream) }
        .refreshable { await dreamStore.fetchDreams() }
    }
}

struct DreamCard: View {
    let dream: Dream
    var body: some View {
        VStack(alignment: .leading) {
            Text(dream.formattedDate).font(Theme.captionFont).foregroundColor(Theme.textMuted)
            Text(dream.previewText).font(Theme.bodySerifFont).foregroundColor(Theme.textPrimary).lineLimit(2).padding(.top, 4)
            Text(dream.interpretationMode == .surface ? "Surface" : "Beneath")
                .font(Theme.captionFont.italic()).foregroundColor(Theme.textMuted).padding(.top, 8)
        }
        .padding(24).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 24).fill(Theme.cardBackground)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.cardBorder, lineWidth: 1)))
    }
}

struct DreamDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dreamStore: DreamStore
    let dream: Dream
    @State private var showDelete = false
    
    var body: some View {
        ZStack {
            VeilBackground()
            ScrollView {
                VStack(alignment: .leading) {
                    HStack {
                        Button("← Back") { dismiss() }.font(Theme.captionFont).foregroundColor(Theme.textSecondary)
                        Spacer()
                        Button(action: { showDelete = true }) {
                            Image(systemName: "trash").foregroundColor(Theme.textMuted)
                        }
                    }.padding(.top, 20)
                    
                    Text(dream.formattedDate).font(Theme.captionFont).foregroundColor(Theme.textMuted).padding(.top, 40)
                    Text(dream.content).font(Theme.bodySerifFont).foregroundColor(Theme.textPrimary).lineSpacing(8).padding(.top, 16)
                    
                    if let interp = dream.interpretation {
                        Divider().padding(.vertical, 40)
                        Text((dream.interpretationMode == .surface ? "Surface" : "Beneath") + " reading".uppercased())
                            .font(Theme.captionFont).foregroundColor(Theme.textMuted).tracking(2).padding(.bottom, 20)
                        Text(interp).font(Font.system(size: 19, design: .serif)).foregroundColor(Theme.textPrimary).lineSpacing(10)
                    }
                }.padding(.horizontal, 32)
            }
        }
        .alert("Delete?", isPresented: $showDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { Task { await dreamStore.deleteDream(dream); dismiss() } }
        }
    }
}
