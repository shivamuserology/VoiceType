import SwiftUI
import AppKit

/// History tab view showing all past transcriptions
struct HistoryView: View {
    @ObservedObject var history: TranscriptionHistory
    @State private var copiedId: UUID?
    @State private var searchText = ""
    
    var filteredEntries: [TranscriptionEntry] {
        if searchText.isEmpty {
            return history.entries
        }
        return history.entries.filter { entry in
            entry.rawText.localizedCaseInsensitiveContains(searchText) ||
            (entry.rewrittenText?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search transcriptions...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            if filteredEntries.isEmpty {
                emptyStateView
            } else {
                // History list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredEntries) { entry in
                            HistoryEntryRow(
                                entry: entry,
                                isCopied: copiedId == entry.id,
                                onCopy: { copyText(entry) },
                                onDelete: { history.delete(entry) }
                            )
                            Divider()
                                .padding(.leading, 44)
                        }
                    }
                }
            }
            
            // Footer with count and clear button
            HStack {
                Text("\(history.entries.count) transcription\(history.entries.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !history.entries.isEmpty {
                    Button(action: { history.clearAll() }) {
                        Text("Clear All")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text(searchText.isEmpty ? "No transcriptions yet" : "No results found")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty ? "Your transcription history will appear here" : "Try a different search term")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func copyText(_ entry: TranscriptionEntry) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(entry.displayText, forType: .string)
        
        // Show copied feedback
        withAnimation(.easeInOut(duration: 0.2)) {
            copiedId = entry.id
        }
        
        // Reset after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                if copiedId == entry.id {
                    copiedId = nil
                }
            }
        }
    }
}

// MARK: - History Entry Row

struct HistoryEntryRow: View {
    let entry: TranscriptionEntry
    let isCopied: Bool
    let onCopy: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Type indicator icon
            VStack {
                ZStack {
                    Circle()
                        .fill(entry.wasRewritten ? Color.blue.opacity(0.15) : Color.gray.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: entry.wasRewritten ? "sparkles" : "waveform")
                        .font(.system(size: 14))
                        .foregroundColor(entry.wasRewritten ? .blue : .secondary)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Timestamp and type badge
                HStack(spacing: 6) {
                    Text(formatDate(entry.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if entry.wasRewritten {
                        Text("AI Rewritten")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                }
                
                // Main text
                Text(entry.displayText)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                // Show original if rewritten
                if entry.wasRewritten && entry.rawText != entry.rewrittenText {
                    HStack(spacing: 4) {
                        Text("Original:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(entry.rawText)
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.8))
                            .lineLimit(1)
                    }
                    .padding(.top, 2)
                }
            }
            
            // Copy button
            Button(action: onCopy) {
                ZStack {
                    if isCopied {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 16))
                            .foregroundColor(isHovered ? .primary : .secondary)
                    }
                }
                .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .help(isCopied ? "Copied!" : "Copy to clipboard")
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(isHovered ? Color(NSColor.controlBackgroundColor).opacity(0.5) : Color.clear)
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            Button(action: onCopy) {
                Label("Copy", systemImage: "doc.on.doc")
            }
            
            if entry.wasRewritten {
                Button(action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(entry.rawText, forType: .string)
                }) {
                    Label("Copy Original", systemImage: "doc.plaintext")
                }
            }
            
            Divider()
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
            return "Today, \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "h:mm a"
            return "Yesterday, \(formatter.string(from: date))"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE, h:mm a"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: date)
        }
    }
}
