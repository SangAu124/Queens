import SwiftUI
import Combine
import Foundation

final class QueensPuzzleViewModel: ObservableObject {
    @Published private(set) var board: QueensPuzzleBoard {
        didSet {
            refreshEasyModeMask()
        }
    }
    @Published var message: String
    @Published var isEasyModeEnabled: Bool = false {
        didSet {
            guard isEasyModeEnabled != oldValue else { return }
            refreshEasyModeMask()
            message = isEasyModeEnabled
            ? "Easy to Play 모드를 켰습니다."
            : "일반 모드로 전환했습니다."
        }
    }
    @Published private(set) var boardSize: Int
    @Published private var easyModeMask: [[Bool]]
    @Published private(set) var isBoardLoading: Bool = false
    
    private let boardGenerationQueue = DispatchQueue(label: "QueensBoardGenerationQueue", qos: .userInitiated)
    private var boardGenerationToken = UUID()
    private var pendingGenerationCount: Int = 0
        
    private let palette: [Color] = [
        Color(hex: "#F2B5D4"),
        Color(hex: "#B6E2A1"),
        Color(hex: "#F8D68E"),
        Color(hex: "#C0D6E8"),
        Color(hex: "#A1D6CA"),
        Color(hex: "#CBAACB"),
        Color(hex: "#E5E5E5"),
        Color(hex: "#E9B3B3"),
        Color(hex: "#F7C59F"),
        Color(hex: "#A0CED9"),
        Color(hex: "#D4A5A5"),
        Color(hex: "#F2F1A4"),
        Color(hex: "#C1A5E8"),
        Color(hex: "#9AD9A6"),
        Color(hex: "#F0B7A4")
    ]
    private let minBoardSize = 4
    private let maxBoardSize = 14
    
    init(size: Int = 8) {
        self.board = QueensPuzzleBoard(size: size)
        self.message = "보드를 탭해서 퀸을 배치하세요."
        self.boardSize = size
        self.easyModeMask = Array(
            repeating: Array(repeating: false, count: size),
            count: size
        )
        refreshEasyModeMask()
    }
    
    var n: Int { board.size }
    var zoneMap: [[Int]] { board.colorZones }
    var rowPlacements: [Int] { board.placements }
    var markMap: [[Bool]] {
        guard isEasyModeEnabled else { return board.markMap }
        var result = board.markMap
        for row in 0..<board.size {
            for column in 0..<board.size {
                if !board.hasQueen(row: row, column: column) && easyModeMask[safe: row]?[safe: column] == true {
                    result[row][column] = true
                }
            }
        }
        return result
    }
    var isSolved: Bool { board.isSolved }
    var placedCount: Int { rowPlacements.filter { $0 != -1 }.count }
    var sizeOptions: [Int] { Array(minBoardSize...maxBoardSize) }
    
    func colorForCell(r: Int, c: Int) -> Color {
        palette[zoneMap[r][c] % palette.count]
    }
    
    func regenerateZones() {
        let size = boardSize
        message = "\(size)x\(size) 보드를 생성 중..."
        generateBoard(of: size, successMessage: "보드를 탭해서 퀸을 배치하세요.")
    }
    
    func resetQueens() {
        guard !isBoardLoading else { return }
        board.resetQueens()
        message = "퀸을 모두 지웠습니다."
        refreshEasyModeMask()
    }
    
    func clearBoardState() {
        guard !isBoardLoading else { return }
        board.resetQueens()
        board.clearMarks()
        message = "모든 표시와 퀸을 초기화했습니다."
        refreshEasyModeMask()
    }
    
    func tapCell(r: Int, c: Int) {
        guard !isBoardLoading else { return }
        if board.hasQueen(row: r, column: c) {
            let result = board.toggleQueen(row: r, column: c)
            switch result {
            case .removed(let position):
                message = "(\(position.row + 1), \(position.column + 1)) 퀸 제거"
            case .placed(let position):
                message = "(\(position.row + 1), \(position.column + 1)) 배치됨"
            case .rejected:
                message = "배치 불가: 행·열·색 중복 또는 인접 대각선 충돌"
            }
            return
        }
        
        if isEasyModeEnabled {
            if board.isMarked(row: r, column: c) {
                board.setMark(row: r, column: c, isMarked: false)
                let result = board.toggleQueen(row: r, column: c)
                switch result {
                case .placed(let position):
                    message = "(\(position.row + 1), \(position.column + 1)) 배치됨"
                    refreshEasyModeMask()
                case .removed(let position):
                    message = "(\(position.row + 1), \(position.column + 1)) 퀸 제거"
                    refreshEasyModeMask()
                case .rejected:
                    board.setMark(row: r, column: c, isMarked: true)
                    message = "배치 불가: 행·열·색 중복 또는 인접 대각선 충돌"
                }
            } else {
                board.setMark(row: r, column: c, isMarked: true)
                message = "(\(r + 1), \(c + 1)) 제외 표시"
            }
            return
        }
        
        if board.isMarked(row: r, column: c) {
            board.setMark(row: r, column: c, isMarked: false)
            let result = board.toggleQueen(row: r, column: c)
            switch result {
            case .placed(let position):
                message = "(\(position.row + 1), \(position.column + 1)) 배치됨"
                refreshEasyModeMask()
            case .removed(let position):
                message = "(\(position.row + 1), \(position.column + 1)) 퀸 제거"
                refreshEasyModeMask()
            case .rejected:
                board.setMark(row: r, column: c, isMarked: true)
                message = "배치 불가: 행·열·색 중복 또는 인접 대각선 충돌"
            }
            return
        }
        
        board.setMark(row: r, column: c, isMarked: true)
        message = "(\(r + 1), \(c + 1)) 제외 표시"
    }
    
    func setBoardSize(_ size: Int) {
        let clamped = min(max(size, minBoardSize), maxBoardSize)
        guard clamped != boardSize else { return }
        message = "\(clamped)x\(clamped) 보드를 생성 중..."
        generateBoard(of: clamped, successMessage: "\(clamped)x\(clamped) 보드를 새로 생성했습니다.")
    }
    
    func hint() {
        guard !isBoardLoading else {
            message = "보드를 생성 중입니다. 잠시만 기다려 주세요."
            return
        }
        let result = board.provideHint()
        switch result {
        case .placed(let position):
            message = "힌트: \(position.row + 1)행은 \(position.column + 1)열"
            refreshEasyModeMask()
        case .corrected(let position):
            message = "힌트: \(position.row + 1)행을 \(position.column + 1)열로 교정"
            refreshEasyModeMask()
        case .solved:
            message = "더 이상 힌트가 필요 없습니다. 이미 정답입니다!"
        case .noSolution:
            message = "이 구성에서는 해답을 찾을 수 없습니다."
        }
    }
    
    private func refreshEasyModeMask() {
        guard isEasyModeEnabled else {
            easyModeMask = Array(
                repeating: Array(repeating: false, count: board.size),
                count: board.size
            )
            return
        }
        easyModeMask = board.forbiddenCells()
    }
    
    private func generateBoard(of size: Int, successMessage: String) {
        let token = UUID()
        boardGenerationToken = token
        pendingGenerationCount += 1
        isBoardLoading = true
#if DEBUG
        print("[Queens] Generating board \(size)x\(size)")
#endif
        boardGenerationQueue.async { [weak self] in
            let newBoard = QueensPuzzleBoard(size: size)
            DispatchQueue.main.async {
                guard let self else { return }
                self.pendingGenerationCount = max(0, self.pendingGenerationCount - 1)
                if self.boardGenerationToken != token {
                    self.isBoardLoading = self.pendingGenerationCount > 0
                    return
                }
#if DEBUG
                print("[Queens] Finished board \(size)x\(size)")
#endif
                self.boardSize = size
                self.board = newBoard
                self.message = successMessage
                self.isBoardLoading = self.pendingGenerationCount > 0 ? true : false
            }
        }
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
