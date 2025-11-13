import SwiftUI

struct ContentView: View {
  @StateObject private var viewModel = QueensPuzzleViewModel()
  @State private var showingInfo = false
  
  var body: some View {
    NavigationStack {
      ZStack {
        LinearGradient(
          colors: [
            Color(hex: "#F7F2E9"),
            Color(hex: "#F2E9F7")
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: 24) {
          header
          boardCard
          Spacer()
        }
        .padding(.top, 24)
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      }
      .navigationTitle("Queens")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          boardMenu
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          statusBadge
        }
      }
    }
    .sheet(isPresented: $showingInfo) {
      RulesSheet(message: viewModel.message, size: viewModel.n)
    }
  }
  
  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("컬러 존 퀸 퍼즐")
          .font(.title3.weight(.semibold))
        Spacer()
        Button {
          showingInfo = true
        } label: {
          Image(systemName: "questionmark.circle.fill")
            .font(.title3)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(Color(hex: "#556991"))
        }
        .accessibilityLabel("게임 정보 보기")
      }
      
      Text(viewModel.message)
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
  }
  
  private var statusBadge: some View {
    Label {
      Text("\(viewModel.placedCount)/\(viewModel.n)")
        .font(.subheadline.weight(.semibold))
    } icon: {
      Image(systemName: viewModel.isSolved ? "checkmark.seal.fill" : "crown.fill")
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(
      Capsule()
        .fill(viewModel.isSolved ? Color.green.opacity(0.2) : Color.secondary.opacity(0.12))
    )
    .foregroundStyle(viewModel.isSolved ? Color.green : Color.primary)
    .accessibilityLabel("배치된 퀸 \(viewModel.placedCount)개 중 \(viewModel.n)개")
  }
  
  private var boardMenu: some View {
    Menu {
      Section("보드 관리") {
        Button {
          viewModel.regenerateZones()
        } label: {
          Label("새 보드", systemImage: "arrow.clockwise")
        }
        .disabled(viewModel.isBoardLoading)
        
        Button {
          viewModel.resetQueens()
        } label: {
          Label("퀸 초기화", systemImage: "eraser.fill")
        }
        .disabled(viewModel.isBoardLoading)
        
        Button {
          viewModel.clearBoardState()
        } label: {
          Label("전체 초기화", systemImage: "trash")
        }
        .disabled(viewModel.isBoardLoading)
      }
      
      Section("보조 기능") {
        Button {
          viewModel.hint()
        } label: {
          Label("힌트", systemImage: "lightbulb")
        }
        .disabled(viewModel.isBoardLoading)
      }
      
      Section("보드 크기") {
        ForEach(viewModel.sizeOptions, id: \.self) { size in
          Button {
            viewModel.setBoardSize(size)
          } label: {
            if size == viewModel.boardSize {
              Label("\(size) x \(size)", systemImage: "checkmark")
            } else {
              Text("\(size) x \(size)")
            }
          }
        }
      }
    } label: {
      Image(systemName: "line.3.horizontal")
        .font(.headline.weight(.semibold))
        .padding(8)
        .background(
          Circle()
            .fill(Color.white.opacity(0.2))
        )
        .foregroundStyle(Color.primary)
    }
    .accessibilityLabel("보드 메뉴")
  }
  
  private var boardCard: some View {
    VStack(spacing: 20) {
      board
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
          RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.ultraThinMaterial)
        )
        .overlay(
          RoundedRectangle(cornerRadius: 28, style: .continuous)
            .strokeBorder(Color.white.opacity(0.6))
        )
        .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 12)
      
      ViewThatFits(in: .horizontal) {
        HStack(spacing: 12) {
          actionButtons
        }
        VStack(spacing: 12) {
          actionButtons
        }
      }
      
      Toggle(isOn: $viewModel.isEasyModeEnabled) {
        Label("Easy to Play", systemImage: "wand.and.stars")
          .font(.subheadline.weight(.semibold))
      }
      .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#6C5B7B")))
      .padding(.horizontal, 8)
    }
  }
  
  @ViewBuilder
  private var actionButtons: some View {
    boardActionButton(
      title: "새 게임",
      systemImage: "play.circle.fill",
      style: .primary,
      action: viewModel.regenerateZones,
      isDisabled: viewModel.isBoardLoading
    )
    
    boardActionButton(
      title: "힌트",
      systemImage: "lightbulb",
      style: .secondary,
      action: viewModel.hint,
      isDisabled: viewModel.isBoardLoading
    )
    
    boardActionButton(
      title: "초기화",
      systemImage: "trash",
      style: .destructive,
      action: viewModel.clearBoardState,
      isDisabled: viewModel.isBoardLoading
    )
  }
  
  private var board: some View {
    GeometryReader { geo in
      let cell = floor(geo.size.width / CGFloat(viewModel.n))
      let size = cell * CGFloat(viewModel.n)
      let isLoading = viewModel.isBoardLoading
      let markMap = viewModel.markMap
      let placements = viewModel.rowPlacements
      let easyMode = viewModel.isEasyModeEnabled
      ZStack {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .fill(LinearGradient(
            colors: [Color.white.opacity(0.8), Color.white.opacity(0.5)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ))
          .frame(width: size, height: size)
          .shadow(color: .black.opacity(0.06), radius: 12, y: 8)
        
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .stroke(Color.black.opacity(0.15), lineWidth: 2)
          .frame(width: size, height: size)
        
        VStack(spacing: 0) {
          ForEach(0..<viewModel.n, id: \.self) { row in
            HStack(spacing: 0) {
              ForEach(0..<viewModel.n, id: \.self) { column in
                ZStack {
                  Rectangle()
                    .fill(
                      viewModel.colorForCell(r: row, c: column)
                        .opacity(0.92)
                    )
                    .overlay {
                      Rectangle()
                        .stroke(Color.white.opacity(0.6), lineWidth: 0.5)
                    }
                  if markMap[row][column],
                     placements[row] != column {
                    Circle()
                      .fill(Color.black.opacity(easyMode ? 0.18 : 0.4))
                      .frame(width: cell * 0.18, height: cell * 0.18)
                      .overlay(
                        Circle()
                          .stroke(Color.white.opacity(0.55), lineWidth: cell * 0.02)
                      )
                      .shadow(color: .black.opacity(0.1), radius: 1.5, y: 0.8)
                  }
                  if placements[row] == column {
                    Text("♛")
                      .font(.system(size: cell * 0.58, weight: .bold))
                      .foregroundStyle(Color.black.opacity(0.85))
                      .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                  }
                }
                .frame(width: cell, height: cell)
                .contentShape(Rectangle())
                .onTapGesture {
                  viewModel.tapCell(r: row, c: column)
                }
                .accessibilityLabel("행 \(row + 1) 열 \(column + 1)")
                .accessibilityAddTraits(
                  placements[row] == column ? .isSelected : []
                )
              }
            }
          }
        }
        .frame(width: size, height: size)
        
        if isLoading {
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.black.opacity(0.08))
            .frame(width: size, height: size)
          ProgressView("새 보드를 준비하는 중...")
            .font(.footnote.weight(.semibold))
            .tint(Color(hex: "#556991"))
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    .frame(maxWidth: 520, minHeight: 360)
    .allowsHitTesting(!viewModel.isBoardLoading)
    .animation(.easeInOut(duration: 0.2), value: viewModel.isBoardLoading)
  }
  
  private enum BoardActionStyle {
    case primary
    case secondary
    case destructive
  }
  
  @ViewBuilder
  private func boardActionButton(
    title: String,
    systemImage: String,
    style: BoardActionStyle,
    action: @escaping () -> Void,
    isDisabled: Bool = false
  ) -> some View {
    Button(action: action) {
      Label(title, systemImage: systemImage)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(capsuleBackground(for: style))
        .foregroundColor(legacyTint(for: style))
        .overlay(
          Capsule()
            .stroke(borderColor(for: style), lineWidth: 1)
        )
        .clipShape(Capsule())
        .opacity(isDisabled ? 0.4 : 1)
    }
    .buttonStyle(PlainButtonStyle())
    .disabled(isDisabled)
  }
  
  private func capsuleBackground(for style: BoardActionStyle) -> Color {
    switch style {
    case .primary:
      return Color.accentColor.opacity(0.12)
    case .secondary:
      return Color.accentColor.opacity(0.08)
    case .destructive:
      return Color.red.opacity(0.12)
    }
  }
  
  private func legacyTint(for style: BoardActionStyle) -> Color {
    switch style {
    case .primary:
      return Color.accentColor
    case .secondary:
      return Color.accentColor.opacity(0.8)
    case .destructive:
      return Color.red.opacity(0.75)
    }
  }
  
  private func borderColor(for style: BoardActionStyle) -> Color {
    switch style {
    case .primary:
      return Color.accentColor.opacity(0.4)
    case .secondary:
      return Color.accentColor.opacity(0.3)
    case .destructive:
      return Color.red.opacity(0.35)
    }
  }
}

private struct RulesSheet: View {
  @Environment(\.dismiss) private var dismiss
  let message: String
  let size: Int
  
  var body: some View {
    NavigationStack {
      List {
        Section("현재 안내") {
          Text(message)
            .font(.callout)
          Text("현재 보드 크기: \(size) x \(size)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        
        Section("게임 목표") {
          Text("각 행과 열마다 하나씩, 그리고 색상 존마다 하나씩 퀸을 배치하세요. 모든 퀸은 서로 인접한 대각선 칸(대각선으로 한 칸 거리)에서 만나서는 안 됩니다.")
            .font(.callout)
        }
        
        Section("플레이 방법") {
          Label("빈 칸을 탭하면 제외 표시(X)가 생깁니다.", systemImage: "xmark")
          Label("X 칸을 다시 탭하면 규칙에 맞으면 퀸이 놓입니다.", systemImage: "crown.fill")
          Label("이미 놓인 퀸을 탭하면 제거됩니다.", systemImage: "trash")
        }
        
        Section("도움말") {
          Label("좌측 상단 메뉴에서 보드 크기를 4~14 사이로 조정할 수 있습니다.", systemImage: "square.grid.3x3.square")
          Label("메뉴에서 새 게임을 선택하면 언제나 해답이 있는 새로운 존 구성이 생성됩니다.", systemImage: "arrow.clockwise")
          Label("힌트는 현재 보드와 양립하는 한 위치를 자동으로 채워 줍니다.", systemImage: "lightbulb")
        }
      }
      .listStyle(.insetGrouped)
      .navigationTitle("게임 정보")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("닫기") {
            dismiss()
          }
        }
      }
    }
  }
}
