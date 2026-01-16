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
        VStack(spacing: 0) {
            // Header: Timestamp & Badge
            HStack(spacing: 8) {
                if entry.wasRewritten {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                    Text("AI Rewrite")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "waveform")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text("Transcription")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                
                Text("•")
                    .foregroundColor(.secondary.opacity(0.5))
                
                Text(formatDate(entry.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
            // Actions (visible on hover)
                if isHovered {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Content
            if entry.wasRewritten {
                // Two-column layout
                HStack(alignment: .top, spacing: 0) {
                    // Original (Left)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("ORIGINAL")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary.opacity(0.7))
                            Spacer()
                            HistoryCopyButton(text: entry.rawText)
                        }
                        Text(entry.rawText)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    
                    // Divider
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 1)
                        .padding(.bottom, 12)
                    
                    // Rewritten (Right)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("REWRITTEN")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.blue.opacity(0.8))
                            Spacer()
                            HistoryCopyButton(text: entry.rewrittenText ?? "")
                        }
                        Text(entry.rewrittenText ?? "")
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            } else {
                // Single column layout
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Spacer()
                        HistoryCopyButton(text: entry.rawText)
                    }
                    Text(entry.rawText)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(nil)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(isHovered ? Color(NSColor.controlBackgroundColor) : Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovered ? Color.primary.opacity(0.1) : Color.clear, lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
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
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: date)
        }
    }
}

struct HistoryCopyButton: View {
    let text: String
    @State private var isCopied = false
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
            
            withAnimation {
                isCopied = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    isCopied = false
                }
            }
        }) {
            HStack(spacing: 4) {
                if isCopied {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                    Text("Copied")
                        .font(.system(size: 10, weight: .medium))
                } else {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                }
            }
            .foregroundColor(isCopied ? .green : (isHovered ? .primary : .secondary))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isHovered ? Color.primary.opacity(0.05) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
