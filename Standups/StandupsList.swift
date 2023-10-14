//
//  StandupsList.swift
//  Standups
//
//  Created by Daniel Personal on 9/10/23.
//

import Dependencies
import Combine
import SwiftUINavigation
import SwiftUI
import IdentifiedCollections

struct DataManager: Sendable {
    var load: @Sendable (URL) throws -> Data
    var save: @Sendable (Data, URL) throws -> Void
}

extension DataManager: DependencyKey {
    static let liveValue = DataManager(
        load: { url in try Data(contentsOf: url) },
        save: { data, url in try data.write(to: url) }
    )
}

extension DependencyValues {
    var dataManager: DataManager {
        get { self[DataManager.self] }
        set { self[DataManager.self] = newValue }
    }
}

@MainActor
final class StandupsListModel: ObservableObject {
    @Published var destination: Destination? {
        didSet { bind() }
    }
    @Published var standups: IdentifiedArrayOf<Standup>
    
    private var destinationCandellable: AnyCancellable?
    private var cancellables: Set<AnyCancellable> = []

    @Dependency(\.dataManager) var dataManager
    @Dependency(\.mainQueue) var mainQueue
    
    enum Destination {
        case add(EditStandupModel)
        case detail(StandupDetailModel)
    }
    
    init(
        destination: Destination? = nil
    ) {
        self.standups = []
        self.destination = destination
        
        loadStandups()
        prepareStandupsToSave()
        bind()
    }
    
    func addStandupButtonTapped() {
        destination = .add(EditStandupModel(standup: Standup(id: Standup.ID(UUID()))))
    }
    
    func dismissAddStandupButtonTapped() {
        destination = nil
    }
    
    func confirmAddStandupButtonTapped() {
        defer {
            destination = nil
        }
        
        guard case let .add(editStandupModel) = destination else {
            return
        }
        
        var standup = editStandupModel.standup
        
        standup.attendees.removeAll { attendee in
            attendee.name.allSatisfy(\.isWhitespace)
        }
        
        if standup.attendees.isEmpty {
            standup.attendees.append(Attendee(id: Attendee.ID(UUID()), name: ""))
        }
        
        standups.append(standup)
    }
    
    func standupTapped(standup: Standup) {
        destination = .detail(StandupDetailModel(standup: standup))
    }
    
    private func bind() {
        switch destination {
        case let .detail(standupDetailModel):
            standupDetailModel.onConfirmDeletion = { [weak self, id = standupDetailModel.standup.id] in
                guard let self else { return }
                
                withAnimation {
                    self.standups.remove(id: id)
                    self.destination = nil
                }
            }
            
            destinationCandellable = standupDetailModel.$standup
                .sink { [weak self] standup in
                    guard let self else { return }
                    
                    self.standups[id: standup.id] = standup
                }
            
        case .add, .none:
            break
        }
    }
    
    private func loadStandups() {
        do {
            standups = try JSONDecoder().decode(
                IdentifiedArray.self,
                from: dataManager.load(.standups)
            )
        } catch {
            // TODO: Alert
        }
    }
    
    private func prepareStandupsToSave() {
        $standups
            .dropFirst()
            .debounce(for: .seconds(1), scheduler: mainQueue)
            .sink { [weak self] standups in
                guard let self else { return }
                do {
                    try self.dataManager.save(
                        JSONEncoder().encode(standups),
                        .standups
                    )
                    
                } catch {
                    // TODO: Alert
                }
            }
            .store(in: &cancellables)
    }
}

struct StandupsList: View {
    
    @ObservedObject var model: StandupsListModel
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(model.standups) { standup in
                    Button {
                        model.standupTapped(standup: standup)
                    } label: {
                        CardView(standup: standup)
                    }
                    .listRowBackground(standup.theme.mainColor)
                }
            }
            .toolbar{
                Button {
                    model.addStandupButtonTapped()
                } label: {
                    Image(systemName: "plus")
                }
            }
            .navigationTitle("Daily Standups")
            .sheet(
                unwrapping: $model.destination,
                case: /StandupsListModel.Destination.add
            ) {  $editStandupModel in
                NavigationStack {
                    EditStandupView(model: editStandupModel)
                        .navigationTitle("New Standup")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Dismiss") {
                                    model.dismissAddStandupButtonTapped()
                                }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Add") {
                                    model.confirmAddStandupButtonTapped()
                                }
                            }
                        }
                }
            }
            .navigationDestination(
                unwrapping: $model.destination,
                case: /StandupsListModel.Destination.detail
            ) { $detailModel in
                StandupDetailView(model: detailModel)
            }
        }
    }
}

struct CardView: View {
    let standup: Standup
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(standup.title)
                .font(.headline)
            Spacer()
            HStack {
                Label("\(standup.attendees.count)", systemImage: "person.3")
                Spacer()
                Label(self.standup.duration.formatted(.units()), systemImage: "clock")
                    .labelStyle(.trailingIcon)
            }
            .font(.caption)
        }
        .padding()
        .foregroundColor(standup.theme.accentColor)
    }
}
    
struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            configuration.icon
        }
    }
}

extension LabelStyle where Self == TrailingIconLabelStyle {
    static var trailingIcon: Self { Self() }
}

extension URL {
    static let standups = Self.documentsDirectory.appending(component: "standups.json")
}

#Preview {
    StandupsList(
        model: StandupsListModel()
    )
}
