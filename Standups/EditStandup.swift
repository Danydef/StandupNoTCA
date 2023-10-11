//
//  EditStandup.swift
//  Standups
//
//  Created by Daniel Personal on 9/10/23.
//

import SwiftUI
import SwiftUINavigation

final class EditStandupModel: ObservableObject {
    @Published var focus: EditStandupView.Field?
    @Published var standup: Standup
    
    init(
        focus: EditStandupView.Field? = .title,
        standup: Standup
    ) {
        self.standup = standup
        
        if self.standup.attendees.isEmpty {
            self.standup.attendees.append(
                Attendee(id: Attendee.ID(UUID()), name: "")
            )
        }
        self.focus = focus
    }
    
    func deleteAttendees(atOffsets indices: IndexSet) {
        standup.attendees.remove(
            atOffsets: indices
        )
        if standup.attendees.isEmpty {
            standup.attendees.append(
                Attendee(id: Attendee.ID(UUID()), name: "")
            )
        }
        let index = min(indices.first!, standup.attendees.count - 1)
        focus = .attendee(standup.attendees[index].id)
    }
    
    func addAttendeeButtonTapped() {
        let attendee = Attendee(id: Attendee.ID(UUID()), name: "")
        standup.attendees
            .append(attendee)
        focus = .attendee(attendee.id)
    }
}

struct EditStandupView: View {
    enum Field: Hashable {
        case attendee(Attendee.ID)
        case title
    }
    
    @FocusState var focus: Field?
    @ObservedObject var model: EditStandupModel
    var body: some View {
        Form {
            Section {
                TextField("Title", text: $model.standup.title)
                    .focused($focus, equals: .title)
                HStack {
                    Slider(
                        value: $model.standup.duration.seconds,
                        in: 5...30, step: 1
                    ) {
                        Text("Length")
                    }
                    Spacer()
                    Text(model.standup.duration.formatted(.units()))
                }
                ThemePicker(selection: $model.standup.theme)
            } header: {
                Text("Standud Info")
            }
            Section {
                ForEach($model.standup.attendees) { $attendee in
                    TextField("Name", text: $attendee.name)
                        .focused($focus, equals: .attendee(attendee.id))
                }
                .onDelete { indices in
                    model.deleteAttendees(atOffsets: indices)
                }
                Button("New attendee") {
                    model.addAttendeeButtonTapped()
                }
            } header: {
                Text("Attendees")
            }
        }
        .bind($model.focus, to: $focus)
    }
}

struct ThemePicker: View {
  @Binding var selection: Theme

  var body: some View {
    Picker("Theme", selection: $selection) {
      ForEach(Theme.allCases) { theme in
        ZStack {
          RoundedRectangle(cornerRadius: 4)
            .fill(theme.mainColor)
          Label(theme.name, systemImage: "paintpalette")
            .padding(4)
        }
        .foregroundColor(theme.accentColor)
        .fixedSize(horizontal: false, vertical: true)
        .tag(theme)
      }
    }
  }
}

extension Duration {
  fileprivate var seconds: Double {
    get { Double(self.components.seconds / 60) }
    set { self = .seconds(newValue * 60) }
  }
}

#Preview {
    WithState(initialValue: Standup.mock) { $standup in
        EditStandupView(model: EditStandupModel(standup: .mock))
    }
}
