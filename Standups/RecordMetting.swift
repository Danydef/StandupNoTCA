//
//  RecordMetting.swift
//  Standups
//
//  Created by Daniel Personal on 11/10/23.
//

import Dependencies
import SwiftUI
import XCTestDynamicOverlay
import SwiftUINavigation
@preconcurrency import Speech

@MainActor
final class RecordMettingModel: ObservableObject {
    let standud: Standup
    
    @Published var destination: Destination?
    @Published var dismiss = false
    @Published var secondsElapsed = 0
    @Published var speakerIndex = 0
    
    private var transcript = ""
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.speechClient) var speechClient
    
    enum Destination {
        case alert(AlertState<AlertAction>)
    }
    
    enum AlertAction {
        case confirmSave
        case confirmDiscard
    }
    
    var onMeetingFinshed: (String) -> Void = unimplemented("RecordMeetingModel.onMeetingFinished")
    
    var durationRemaining: Duration {
        standud.duration - .seconds(secondsElapsed)
    }
    
    init(
        destination: Destination? = nil,
        standud: Standup
    ) {
        self.destination = destination
        self.standud = standud
    }
    
    var isAlertOpen: Bool {
        switch destination {
        case .alert:
            return true
        case .none:
            return false
        }
    }
    
    func nextButtonTapped() {
        guard speakerIndex < standud.attendees.count - 1 else {
            destination = .alert(
                AlertState(
                    title: TextState("End meeting?"),
                    message: TextState("You are ending the meeting early. Want would yo like to do?"),
                    buttons: [
                        .default(TextState("Save and end"), action: .send(.confirmSave)),
                        .cancel(TextState("Resume"))
                    ]
                )
            )
            return
        }
        
        speakerIndex += 1
        secondsElapsed = speakerIndex * Int(standud.durationPerAttendee.components.seconds)
    }
    
    func endMeetingButtonTapped() {
        destination = .alert(
            AlertState(
                title: TextState("End meeting?"),
                message: TextState("You are ending the meeting early. Want would yo like to do?"),
                buttons: [
                    .default(TextState("Save and end"), action: .send(.confirmSave)),
                    .destructive(TextState("Discard"), action: .send(.confirmDiscard)),
                    .cancel(TextState("Resume"))
                ]
            )
        )
    }
    
    func alertButtonTapped(_ action: AlertAction?) {
        switch action {
        case .confirmSave:
            dismiss = true
            onMeetingFinshed(transcript)
        case .confirmDiscard:
            dismiss = true
        case .none:
            break
        }
    }
    
    @MainActor
    func task() async {
        let authorizationStatus = await speechClient.requestAuthorization()
        
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                if authorizationStatus == .authorized {
                    group.addTask {
                        try await self.startSpeechRecognition()
                    }
                }

                group.addTask {
                    try await self.startTimer()
                }
                
                try await group.waitForAll()
            }
        } catch {
            destination = .alert(
                AlertState(title: TextState("Something went wrong"))
            )
        }
    }
    
    private func startSpeechRecognition() async throws {
        let request = SFSpeechAudioBufferRecognitionRequest()
        for try await result in await speechClient.startTask(request) {
            transcript =  result.bestTranscription.formattedString
        }
    }
    
    private func startTimer() async throws {
        for await _ in clock.timer(interval: .seconds(1)) where !isAlertOpen  {
            secondsElapsed += 1
            
            if secondsElapsed.isMultiple(of: Int(standud.durationPerAttendee.components.seconds)) {
                if speakerIndex == standud.attendees.count - 1 {
                    onMeetingFinshed(transcript)
                    dismiss = true
                    break
                }
                speakerIndex += 1
            }
        }
    }
}

struct RecordMettingView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var model: RecordMettingModel
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(model.standud.theme.mainColor)
            VStack {
                MeetingHeaderView(
                    secondsElapsed: model.secondsElapsed,
                    durationRemaining: model.durationRemaining,
                    theme: model.standud.theme
                )
                MeetingTimerView(
                    standup: model.standud,
                    speakerIndex: model.speakerIndex
                )
                MeetingFooterView(
                    standup: model.standud,
                    nextButtonTapped: {
                        model.nextButtonTapped()
                    },
                    speakerIndex: model.speakerIndex
                )
            }
        }
        .padding()
        .foregroundColor(model.standud.theme.accentColor)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("End meeting") {
                    model.endMeetingButtonTapped()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await model.task()
        }
        .onChange(of: model.dismiss) { dismiss() }
        .alert(
            unwrapping: $model.destination,
            case: /RecordMettingModel.Destination.alert
        ) { action in
                model.alertButtonTapped(action)
        }
    }
}

struct MeetingHeaderView: View {
    let secondsElapsed: Int
    let durationRemaining: Duration
    let theme: Theme
    
    var body: some View {
        VStack {
            ProgressView(value: progress)
                .progressViewStyle(
                    MeetingProgressViewStyle(theme: theme)
                )
            HStack {
                VStack(alignment: .leading) {
                    Text("Seconds Elapsed")
                        .font(.caption)
                    Label(
                        "\(secondsElapsed)",
                        systemImage: "hourglass.bottomhalf.fill"
                    )
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Seconds Remaining")
                        .font(.caption)
                    Label(
                        durationRemaining.formatted(.units()),
                        systemImage: "hourglass.tophalf.fill"
                    )
                    .font(.body.monospacedDigit())
                    .labelStyle(.trailingIcon)
                }
            }
        }
        .padding([.top, .horizontal])
    }
    
    private var totalDuration: Duration {
        .seconds(secondsElapsed)
        + self.durationRemaining
    }
    
    private var progress: Double {
        guard totalDuration > .seconds(0) else { return 0 }
        return Double(secondsElapsed)
        / Double(totalDuration.components.seconds)
    }
}

struct MeetingProgressViewStyle: ProgressViewStyle {
    var theme: Theme
    
    func makeBody(
        configuration: Configuration
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10.0)
                .fill(theme.accentColor)
                .frame(height: 20.0)
            
            ProgressView(configuration)
                .tint(theme.mainColor)
                .frame(height: 12.0)
                .padding(.horizontal)
        }
    }
}

struct MeetingTimerView: View {
    let standup: Standup
    let speakerIndex: Int
    
    var body: some View {
        Circle()
            .strokeBorder(lineWidth: 24)
            .overlay {
                VStack {
                    Text(currentSpeakerName)
                        .font(.title)
                    Text("is speaking")
                    Image(systemName: "mic.fill")
                        .font(.largeTitle)
                        .padding(.top)
                }
                .foregroundStyle(standup.theme.accentColor)
            }
            .overlay {
                ForEach(
                    Array(standup.attendees.enumerated()),
                    id: \.element.id
                ) { index, attendee in
                    if index < speakerIndex + 1 {
                        SpeakerArc(
                            totalSpeakers: standup.attendees.count,
                            speakerIndex: index
                        )
                        .rotation(Angle(degrees: -90))
                        .stroke(
                            standup.theme.mainColor,
                            lineWidth: 12
                        )
                    }
                }
            }
            .padding(.horizontal)
    }
    
    private var currentSpeakerName: String {
        guard
            self.speakerIndex < standup.attendees.count
        else { return "Someone" }
        return self.standup
            .attendees[speakerIndex].name
    }
}

struct SpeakerArc: Shape {
    let totalSpeakers: Int
    let speakerIndex: Int
    
    private var degreesPerSpeaker: Double {
        360.0 / Double(totalSpeakers)
    }
    private var startAngle: Angle {
        Angle(
            degrees: degreesPerSpeaker
            * Double(speakerIndex)
            + 1.0
        )
    }
    private var endAngle: Angle {
        Angle(
            degrees: startAngle.degrees
            + degreesPerSpeaker
            - 1.0
        )
    }
    
    func path(in rect: CGRect) -> Path {
        let diameter = min(
            rect.size.width, rect.size.height
        ) - 24.0
        let radius = diameter / 2.0
        let center = CGPoint(x: rect.midX, y: rect.midY)
        return Path { path in
            path.addArc(
                center: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
        }
    }
}

struct MeetingFooterView: View {
    let standup: Standup
    var nextButtonTapped: () -> Void
    let speakerIndex: Int
    
    var body: some View {
        VStack {
            HStack {
                Text(speakerText)
                Spacer()
                Button(action: nextButtonTapped) {
                    Image(systemName: "forward.fill")
                }
            }
        }
        .padding([.bottom, .horizontal])
    }
    
    private var speakerText: String {
        guard
            self.speakerIndex
                < self.standup.attendees.count - 1
        else {
            return "No more speakers."
        }
        return """
      Speaker \(speakerIndex + 1) \
      of \(standup.attendees.count)
      """
    }
}

#Preview {
    NavigationView {
        RecordMettingView(
            model: RecordMettingModel(standud: .mock)
        )
    }
}
