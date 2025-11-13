//
//  QueensTests.swift
//  QueensTests
//
//  Created by 상데브 on 11/5/25.
//

import Testing
@testable import Queens

struct QueensTests {
    @Test func preventsAdjacentDiagonalConflict() throws {
        var board = QueensPuzzleBoard(size: 4)
        board.loadTestingZoneMap([
            [0, 1, 2, 3],
            [0, 1, 2, 3],
            [0, 1, 2, 3],
            [0, 1, 2, 3]
        ])
        
        let first = board.toggleQueen(row: 0, column: 0)
        #expect({
            if case .placed = first { return true }
            return false
        }(), "첫 번째 퀸 배치가 실패했습니다.")
        
        let second = board.toggleQueen(row: 1, column: 1)
        #expect({
            if case .rejected = second { return true }
            return false
        }(), "인접 대각선 배치는 거부되어야 합니다.")
    }
    
    @Test func allowsNonAdjacentDiagonalPlacement() throws {
        var board = QueensPuzzleBoard(size: 4)
        board.loadTestingZoneMap([
            [0, 1, 2, 3],
            [0, 1, 2, 3],
            [0, 1, 2, 3],
            [0, 1, 2, 3]
        ])
        
        let first = board.toggleQueen(row: 0, column: 0)
        #expect({
            if case .placed = first { return true }
            return false
        }(), "첫 번째 퀸 배치가 실패했습니다.")
        
        let second = board.toggleQueen(row: 2, column: 2)
        #expect({
            if case .placed = second { return true }
            return false
        }(), "두 칸 이상 떨어진 대각선 배치는 허용되어야 합니다.")
    }
    
    @Test func hintSolverFindsSolution() throws {
        var board = QueensPuzzleBoard(size: 4)
        board.loadTestingZoneMap([
            [0, 1, 2, 3],
            [0, 1, 2, 3],
            [0, 1, 2, 3],
            [0, 1, 2, 3]
        ])
        
        for _ in 0..<(board.size * 2) {
            let result = board.provideHint()
            #expect({
                if case .noSolution = result { return false }
                return true
            }(), "해답이 존재해야 합니다.")
            if board.isSolved { break }
        }
        
        #expect(board.isSolved, "힌트를 반복 호출하면 퍼즐이 해결되어야 합니다.")
        #expect(board.placements.allSatisfy { $0 != -1 }, "모든 행에 퀸이 배치되어야 합니다.")
    }
    
    @Test func hintSolverDetectsNoSolution() throws {
        var board = QueensPuzzleBoard(size: 4)
        board.loadTestingZoneMap([
            [0, 0, 1, 1],
            [0, 0, 1, 1],
            [2, 2, 2, 2],
            [2, 2, 2, 2]
        ])
        
        let result = board.provideHint()
        #expect({
            if case .noSolution = result { return true }
            return false
        }(), "존재하지 않는 해답을 올바르게 감지해야 합니다.")
    }
    
    @Test func forbiddenCellsMarkConflictingPositions() throws {
        var board = QueensPuzzleBoard(size: 4)
        board.loadTestingZoneMap([
            [0, 0, 1, 1],
            [0, 0, 1, 1],
            [2, 2, 3, 3],
            [2, 2, 3, 3]
        ])
        
        let result = board.toggleQueen(row: 2, column: 2)
        #expect({
            if case .placed = result { return true }
            return false
        }(), "초기 퀸 배치가 실패했습니다.")
        
        let blocked = board.forbiddenCells()
        #expect(blocked[2][0], "같은 행의 칸은 차단되어야 합니다.")
        #expect(blocked[0][2], "같은 열의 칸은 차단되어야 합니다.")
        #expect(blocked[3][3], "같은 존의 칸은 차단되어야 합니다.")
        #expect(blocked[1][1], "인접 대각선 칸은 차단되어야 합니다.")
        #expect(blocked[2][2] == false, "퀸이 놓인 칸은 차단되어서는 안 됩니다.")
    }
    
    @Test func forbiddenCellsRemainClearWithoutQueens() throws {
        var board = QueensPuzzleBoard(size: 4)
        board.loadTestingZoneMap([
            [0, 0, 1, 1],
            [0, 0, 1, 1],
            [2, 2, 3, 3],
            [2, 2, 3, 3]
        ])
        
        let blocked = board.forbiddenCells()
        let hasBlocked = blocked.flatMap { $0 }.contains(true)
        #expect(hasBlocked == false, "퀸이 없을 때는 차단된 칸이 없어야 합니다.")
    }
}
