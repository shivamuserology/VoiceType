import Foundation

/// A single transcription history entry
struct TranscriptionEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let rawText: String
    let rewrittenText: String?
    let wasRewritten: Bool
    
    init(rawText: String, rewrittenText: String? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.rawText = rawText
        self.rewrittenText = rewrittenText
        self.wasRewritten = rewrittenText != nil
    }
    
    /// The display text (rewritten if available, otherwise raw)
    var displayText: String {
        rewrittenText ?? rawText
    }
}

/// Manages transcription history persistence
class TranscriptionHistory: ObservableObject {
    @Published var entries: [TranscriptionEntry] = []
    
    private let maxEntries = 100
    private let storageKey = "transcriptionHistory"
    
    init() {
        loadFromDisk()
    }
    
    // MARK: - Public Methods
    
    /// Add a new transcription (raw only, no rewrite)
    func addTranscription(_ rawText: String) {
        let entry = TranscriptionEntry(rawText: rawText)
        insertEntry(entry)
    }
    
    /// Add a transcription with rewrite
    func addTranscriptionWithRewrite(raw: String, rewritten: String) {
        let entry = TranscriptionEntry(rawText: raw, rewrittenText: rewritten)
        insertEntry(entry)
    }
    
    /// Clear all history
    func clearAll() {
        entries.removeAll()
        saveToDisk()
    }
    
    /// Delete a specific entry
    func delete(_ entry: TranscriptionEntry) {
        entries.removeAll { $0.id == entry.id }
        saveToDisk()
    }
    
    /// Delete entries at indices
    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        saveToDisk()
    }
    
    // MARK: - Private Methods
    
    private func insertEntry(_ entry: TranscriptionEntry) {
        entries.insert(entry, at: 0)
        
        // Trim if exceeding max entries
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        
        saveToDisk()
    }
    
    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("[TranscriptionHistory] Failed to save: \(error)")
        }
    }
    
    private func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        
        do {
            entries = try JSONDecoder().decode([TranscriptionEntry].self, from: data)
        } catch {
            print("[TranscriptionHistory] Failed to load: \(error)")
        }
    }
}
