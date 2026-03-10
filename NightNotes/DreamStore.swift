import SwiftUI

@MainActor
class DreamStore: ObservableObject {
    @Published var dreams: [Dream] = []
    @Published var isLoading = false
    @Published var isInterpreting = false
    @Published var error: String?
    @Published var currentInterpretation: InterpretationResponse?
    
    private let supabase = SupabaseClient.shared
    
    var groupedDreams: [DreamGroup] { dreams.groupedByMonth() }
    var dreamCount: Int { dreams.count }
    
    func fetchDreams() async {
        guard let session = try? await supabase.auth.session else { return }
        isLoading = true
        do {
            let fetched: [Dream] = try await supabase.database
                .from("dreams").select().eq("user_id", value: session.user.id.uuidString)
                .order("created_at", ascending: false).execute().value
            self.dreams = fetched
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }
    
    func interpretDream(_ content: String, mode: InterpretationMode) async -> InterpretationResponse? {
        isInterpreting = true; error = nil; currentInterpretation = nil
        do {
            let response = try await supabase.interpret(dream: content, mode: mode)
            currentInterpretation = response
            await fetchDreams()
            isInterpreting = false
            return response
        } catch let e as APIError {
            self.error = e.localizedDescription
        } catch {
            self.error = "Failed to interpret"
        }
        isInterpreting = false
        return nil
    }
    
    func deleteDream(_ dream: Dream) async {
        do {
            try await supabase.database.from("dreams").delete().eq("id", value: dream.id.uuidString).execute()
            dreams.removeAll { $0.id == dream.id }
        } catch { self.error = error.localizedDescription }
    }
}
