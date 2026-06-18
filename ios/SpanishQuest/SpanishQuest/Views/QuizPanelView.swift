import SwiftUI

struct QuizPanelView: View {
    @ObservedObject var viewModel: BattleViewModel
    @State private var typedAnswer = ""
    @FocusState private var isAnswerFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.actor.label)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(viewModel.actor == .player ? Color(red: 0.35, green: 0.92, blue: 0.95) : Color(red: 0.94, green: 0.68, blue: 0.28))
                    Text(viewModel.prompt.mode.title)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                Text(viewModel.attempt == 1 ? "First try" : "Focus try")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.86))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                    )
            }

            HStack(alignment: .center, spacing: 10) {
                Text(viewModel.prompt.question)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.72)
                    .lineLimit(2)

                if viewModel.prompt.audioPath != nil {
                    Button {
                        viewModel.playPromptAudio()
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color(red: 0.16, green: 0.55, blue: 0.58)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Play audio prompt")
                }
            }

            Text(viewModel.feedback)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(2)
                .frame(minHeight: 36, alignment: .topLeading)

            if viewModel.status == .fighting {
                HStack(spacing: 10) {
                    TextField("Type your answer", text: $typedAnswer)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .focused($isAnswerFocused)
                        .onSubmit(submitAnswer)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.18, green: 0.13, blue: 0.10))
                                .stroke(Color(red: 0.82, green: 0.55, blue: 0.22), lineWidth: 1)
                        )

                    Button {
                        submitAnswer()
                    } label: {
                        Text("Submit")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 94)
                            .frame(minHeight: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(typedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.35) : Color(red: 0.16, green: 0.48, blue: 0.42))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(typedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            if viewModel.status != .fighting {
                Button {
                    viewModel.restart()
                } label: {
                    Text(viewModel.status == .won ? "Fight Again" : "Retry Battle")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.16, green: 0.48, blue: 0.42))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 16)
        .onAppear {
            isAnswerFocused = true
        }
        .onChange(of: viewModel.prompt.id) { _, _ in
            typedAnswer = ""
            isAnswerFocused = true
        }
        .onChange(of: viewModel.attempt) { _, _ in
            typedAnswer = ""
            isAnswerFocused = true
        }
    }

    private func submitAnswer() {
        let answer = typedAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !answer.isEmpty else {
            return
        }

        viewModel.answer(answer)
        typedAnswer = ""
    }
}
