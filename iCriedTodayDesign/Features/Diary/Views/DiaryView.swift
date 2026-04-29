import SwiftUI

struct DiaryView: View {
    @ObservedObject var dataManager: TearDataManager
    @StateObject private var viewModel: DiaryViewModel
    
    init(dataManager: TearDataManager) {
        self.dataManager = dataManager
        _viewModel = StateObject(wrappedValue: DiaryViewModel(dataManager: dataManager))
    }
    
    var body: some View {
        VStack(spacing: -5) {
            headerView
            
            if viewModel.isEmpty {
                EmptyStateView(
                    title: "Начните свой путь",
                    subtitle: "Запишите свой первый момент грусти и начните путешествие к самопознанию",
                    icon: "drop.fill",
                    buttonTitle: "Добавить запись",
                    action: { viewModel.showingAddTear = true }
                )
                .transition(.opacity)
            } else {
                entriesList
                    .refreshable {
                        await viewModel.refresh()
                    }
            }
        }
        .id(dataManager.refreshTrigger)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isEmpty)
        .sheet(isPresented: $viewModel.showingAddTear) {
            AddTearView(
                availableTags: viewModel.availableTags,
                availableEmojiIntensities: viewModel.availableEmojiIntensities,
                onSave: { newEntry in
                    viewModel.addEntry(newEntry)
                }
            )
        }
        .alert("Удалить запись?", isPresented: $viewModel.showingDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.confirmDelete()
                }
            }
        } message: {
            Text("Это действие нельзя отменить")
        }
        .onAppear {
            viewModel.syncFromDataManager()
        }
        .onChange(of: dataManager.refreshTrigger) { _ in
            viewModel.syncFromDataManager()
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("Мой Дневник")
                .font(.title)
                .fontWeight(.bold)
            Spacer()
            Button(action: { viewModel.showingAddTear = true }) {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.blue))
            }
        }
        .padding()
    }
    
    private var entriesList: some View {
        List {
            ForEach(viewModel.sections) { section in
                entriesSection(for: section)
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private func entriesSection(for section: DiarySection) -> some View {
        Section(header: Text(section.monthTitle)
            .font(.headline)
            .foregroundColor(.gray)) {
                ForEach(section.records) { entry in
                    entryRow(for: entry)
                        .transition(.opacity)
                }
                .animation(.easeInOut(duration: 0.3), value: section.records)
            }
    }
    
    private func entryRow(for entry: TearEntry) -> some View {
        TearCard(entry: entry, dataManager: dataManager)
            .id(entry.id)
            .swipeActions(allowsFullSwipe: false) {
                Button() {
                    viewModel.presentDelete(for: entry)
                } label: {
                    Label("Удалить", systemImage: "trash")
                }
                .tint(.red)
            }
    }
}
