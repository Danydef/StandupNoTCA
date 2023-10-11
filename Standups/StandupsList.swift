//
//  StandupsList.swift
//  Standups
//
//  Created by Daniel Personal on 9/10/23.
//

import Combine
import SwiftUINavigation
import SwiftUI
import IdentifiedCollections

final class StandupsListModel: ObservableObject {
    @Published var destination: Destination? {
        didSet { bind() }
    }
    @Published var standups: IdentifiedArrayOf<Standup>
    
    private var destinationCandellable: AnyCancellable?

    enum Destination {
        case add(EditStandupModel)
        case detail(StandupDetailModel)
    }
    
    init(
        destination: Destination? = nil,
        standups: IdentifiedArrayOf<Standup> = []
    ) {
        self.standups = standups
        self.destination = destination
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

#Preview {
    StandupsList(
        model: StandupsListModel(
            standups: [
                .mock
            ]
        )
    )
}
