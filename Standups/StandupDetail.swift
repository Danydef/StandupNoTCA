//
//  StandupDetail.swift
//  Standups
//
//  Created by Daniel Personal on 10/10/23.
//

import Dependencies
import SwiftUI
import SwiftUINavigation
import XCTestDynamicOverlay

@MainActor
final class StandupDetailModel: ObservableObject {
    @Published var destination: Destination? {
        didSet {
            bind()
        }
    }
    @Published var standup: Standup
    
    @Dependency(\.continuousClock) var clock
    
    var onConfirmDeletion: () -> Void = unimplemented("StadupDetailModel.onComfirmationDeletion")
    
    enum Destination {
        case alert(AlertState<AlertAction>)
        case edit(EditStandupModel)
        case meeting(Meeting)
        case record(RecordMettingModel)
    }
    
    enum AlertAction {
        case confirmDeletion
    }
    
    init(
        destination: Destination? = nil,
        standup: Standup
    ) {
        self.destination = destination
        self.standup = standup
        bind()
    }
    
    func deleteMeetings(atOffsets indices: IndexSet) {
        standup.meetings.remove(atOffsets: indices)
    }
    
    func meetingTapping(_ meeting: Meeting) {
        destination = .meeting(meeting)
    }
    
    func deleteButtonTapped() {
        destination = .alert(.delete)
    }
    
    func alertButtonTapped(_ action: AlertAction?) {
        switch action {
        case .confirmDeletion:
            onConfirmDeletion()
        case .none:
            break
        }
    }
    
    func editButtonTapped() {
        destination = .edit(EditStandupModel(standup: standup))
    }
    
    func cancelEditingButtonTapped() {
        destination = nil
    }
    
    func doneEditingButtonTapped() {
        guard case let .edit(model) = destination else { return }
        
        standup = model.standup
        destination = nil
    }
    
    func startMettingButtonTapped() {
        destination = .record(
            RecordMettingModel(
                standud: standup
            )
        )
    }
    
    private func bind() {
        switch destination {
        case let .record(recordMettingModel):
            recordMettingModel.onMeetingFinshed = { [weak self] transcript in
                guard let self else { return }
                
                Task {
                    try? await self.clock.sleep(for: .milliseconds(400))
                    withAnimation {
                        _ = self.standup.meetings.insert(
                            Meeting(
                                id: Meeting.ID(UUID()),
                                date: Date(),
                                transcript: transcript
                            ),
                            at: 0
                        )
                    }
                }
                //self.destination = nil
            }
        case .edit, .meeting, .alert, .none:
            break
        }
    }
}

extension AlertState where Action == StandupDetailModel.AlertAction {
    static let delete = AlertState(
        title: TextState("Delete?"),
        message: TextState(
            """
            Are you sure you want to delete this meeting?
            """
        ),
        buttons: [
            .destructive(
                TextState("Yes"), action: .send(.confirmDeletion)
            ),
            .cancel(TextState("Nevermind"))
        ]
    )
}

struct StandupDetailView: View {
    @ObservedObject var model: StandupDetailModel
    var body: some View {
        List {
            Section {
                Button {
                    model.startMettingButtonTapped()
                } label: {
                    Label("Start Meeting", systemImage: "timer")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
                HStack {
                    Label("Length", systemImage: "clock")
                    Spacer()
                    Text(self.model.standup.duration.formatted(.units()))
                }
                
                HStack {
                    Label("Theme", systemImage: "paintpalette")
                    Spacer()
                    Text(self.model.standup.theme.name)
                        .padding(4)
                        .foregroundColor(self.model.standup.theme.accentColor)
                        .background(self.model.standup.theme.mainColor)
                        .cornerRadius(4)
                }
            } header: {
                Text("Standup Info")
            }
            
            if !model.standup.meetings.isEmpty {
                Section {
                    ForEach(model.standup.meetings) { meeting in
                        Button {
                            model.meetingTapping(meeting)
                        } label: {
                            HStack {
                                Image(systemName: "calendar")
                                Text(meeting.date, style: .date)
                                Text(meeting.date, style: .time)
                            }
                        }
                    }
                    .onDelete { indices in
                        model.deleteMeetings(atOffsets: indices)
                    }
                } header: {
                    Text("Past meetings")
                }
            }
            
            Section {
                ForEach(self.model.standup.attendees) { attendee in
                    Label(attendee.name, systemImage: "person")
                }
            } header: {
                Text("Attendees")
            }
            
            Section {
                Button("Delete") {
                    model.deleteButtonTapped()
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(self.model.standup.title)
        .toolbar {
            Button("Edit") {
                model.editButtonTapped()
            }
        }
        .navigationDestination(
            unwrapping: $model.destination,
            case: /StandupDetailModel.Destination.meeting
        ) { $meeting in
            MeetingView(meeting: meeting, standup: model.standup)
        }
        .navigationDestination(
            unwrapping: $model.destination,
            case: /StandupDetailModel.Destination.record
        ) { $record in
            RecordMettingView(model: record)
        }
        .alert(
            unwrapping: $model.destination,
            case: /StandupDetailModel.Destination.alert
        ) { action in
            model.alertButtonTapped(action)
        }
        .sheet(
            unwrapping: $model.destination,
            case: /StandupDetailModel.Destination.edit
        ) { $editModel in
            NavigationView {
                EditStandupView(model: editModel)
                    .navigationTitle(model.standup.title)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Candel") {
                                model.cancelEditingButtonTapped()
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                model.doneEditingButtonTapped()
                            }
                        }
                    }
            }
        }
    }
}

struct MeetingView: View {
    let meeting: Meeting
    let standup: Standup
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Divider()
                    .padding(.bottom)
                Text("Attendees")
                    .font(.headline)
                ForEach(standup.attendees) { attendee in
                    Text(attendee.name)
                }
                Text("Transcript")
                    .font(.headline)
                    .padding(.top)
                Text(meeting.transcript)
            }
        }
        .navigationTitle(Text(meeting.date, style: .date))
        .padding()
    }
}

#Preview {
    NavigationStack {
        StandupDetailView(model: StandupDetailModel(standup: .mock))
    }
}
