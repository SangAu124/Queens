import Foundation

struct QueensPuzzleBoard {
  struct Position {
    let row: Int
    let column: Int
  }
  
  enum PlacementResult {
    case placed(Position)
    case removed(Position)
    case rejected
  }
  
  enum HintResult {
    case placed(Position)
    case corrected(Position)
    case solved
    case noSolution
  }
  
  let size: Int
  private(set) var zoneMap: [[Int]]
  private(set) var rowPlacements: [Int]
  private(set) var marks: [[Bool]]
  private var cachedSolution: [Int]?
  private var zoneCellLookup: [[Position]]
  private var zoneCounts: [Int]
  private var columnPriorityForRow: [[Int]]
  
  init(size: Int) {
    self.size = size
    self.zoneMap = []
    self.rowPlacements = []
    self.marks = []
    self.cachedSolution = nil
    self.zoneCellLookup = []
    self.zoneCounts = []
    self.columnPriorityForRow = []
    regenerateZones()
  }
  
  mutating func regenerateZones() {
    rowPlacements = Array(repeating: -1, count: size)
    marks = Array(
      repeating: Array(repeating: false, count: size),
      count: size
    )
    
    let attemptLimit = min(24, max(8, size * 2))
    for _ in 0..<attemptLimit {
      zoneMap = Self.makeStructuredZoneMap(n: size)
      let summary = Self.zoneSizeSummary(in: zoneMap)
      guard summary.small >= 2, summary.medium >= 1 else { continue }
      rebuildCaches()
      cachedSolution = findSolutionRespectingCurrent()
      if cachedSolution != nil {
        return
      }
    }
    
    zoneMap = Self.makeFallbackZoneMap(n: size)
    rebuildCaches()
    cachedSolution = findSolutionRespectingCurrent()
  }
  
  mutating func resetQueens() {
    rowPlacements = Array(repeating: -1, count: size)
    cachedSolution = nil
  }
  
  mutating func clearMarks() {
    for row in 0..<size {
      for column in 0..<size {
        marks[row][column] = false
      }
    }
  }
  
  mutating func toggleQueen(row: Int, column: Int) -> PlacementResult {
    if rowPlacements[row] == column {
      rowPlacements[row] = -1
      marks[row][column] = false
      cachedSolution = nil
      return .removed(Position(row: row, column: column))
    }
    let previous = rowPlacements[row]
    rowPlacements[row] = -1
    if canPlaceQueen(row: row, column: column) {
      rowPlacements[row] = column
      marks[row][column] = false
      cachedSolution = nil
      return .placed(Position(row: row, column: column))
    } else {
      rowPlacements[row] = previous
      return .rejected
    }
  }
  
  mutating func setMark(row: Int, column: Int, isMarked: Bool) {
    marks[row][column] = isMarked
  }
  
  func isMarked(row: Int, column: Int) -> Bool {
    marks[row][column]
  }
  
  func hasQueen(row: Int, column: Int) -> Bool {
    rowPlacements[row] == column
  }
  
  mutating func provideHint() -> HintResult {
    if cachedSolution == nil {
      cachedSolution = findSolutionRespectingCurrent()
    }
    guard let solution = cachedSolution else {
      return .noSolution
    }
    if let emptyRow = rowPlacements.firstIndex(of: -1) {
      rowPlacements[emptyRow] = solution[emptyRow]
      marks[emptyRow][solution[emptyRow]] = false
      return .placed(Position(row: emptyRow, column: solution[emptyRow]))
    }
    for row in 0..<size where rowPlacements[row] != solution[row] {
      rowPlacements[row] = solution[row]
      marks[row][solution[row]] = false
      return .corrected(Position(row: row, column: solution[row]))
    }
    return .solved
  }
  
  var isSolved: Bool {
    guard rowPlacements.allSatisfy({ $0 != -1 }) else { return false }
    let columns = Set(rowPlacements)
    guard columns.count == size else { return false }
    let zones = Set((0..<size).map { zoneMap[$0][rowPlacements[$0]] })
    guard zones.count == size else { return false }
    return noAdjacentDiagonalConflicts()
  }
  
  // MARK: - Internal helpers
  
  private func canPlaceQueen(row: Int, column: Int) -> Bool {
    for r in 0..<size where rowPlacements[r] != -1 {
      if rowPlacements[r] == column { return false }
    }
    let zone = zoneMap[row][column]
    for r in 0..<size where rowPlacements[r] != -1 {
      if zoneMap[r][rowPlacements[r]] == zone { return false }
    }
    for r in 0..<size where rowPlacements[r] != -1 {
      let c = rowPlacements[r]
      if abs(r - row) == 1 && abs(c - column) == 1 { return false }
    }
    return true
  }
  
    private func noAdjacentDiagonalConflicts() -> Bool {
        for i in 0..<size {
            let ci = rowPlacements[i]
            for j in (i + 1)..<size {
                let cj = rowPlacements[j]
        if ci == -1 || cj == -1 { continue }
        if abs(i - j) == 1 && abs(ci - cj) == 1 { return false }
      }
    }
    return true
  }
  
  private mutating func findSolutionRespectingCurrent() -> [Int]? {
    let n = size
    var placement = Array(repeating: -1, count: n)
    var usedColumnsMask: UInt64 = 0
    var usedZonesMask: UInt64 = 0
    var unresolvedRows: [Int] = []
    
    for row in 0..<n {
      let column = rowPlacements[row]
      if column == -1 {
        unresolvedRows.append(row)
        continue
      }
      let zone = zoneMap[row][column]
      let columnBit = UInt64(1) << UInt64(column)
      if (usedColumnsMask & columnBit) != 0 {
        return nil
      }
      let zoneBit = UInt64(1) << UInt64(zone)
      if (usedZonesMask & zoneBit) != 0 {
        return nil
      }
      if row > 0 {
        let prev = rowPlacements[row - 1]
        if prev != -1 && abs(prev - column) == 1 {
          return nil
        }
      }
      if row + 1 < n {
        let next = rowPlacements[row + 1]
        if next != -1 && abs(next - column) == 1 {
          return nil
        }
      }
      placement[row] = column
      usedColumnsMask |= columnBit
      usedZonesMask |= zoneBit
    }
    
    func candidateColumns(for row: Int, usedColumns: UInt64, usedZones: UInt64, limit: Int? = nil) -> [Int] {
      var result: [Int] = []
      let limitValue = limit ?? Int.max
      for column in columnPriorityForRow[row] {
        let columnBit = UInt64(1) << UInt64(column)
        if (usedColumns & columnBit) != 0 {
          continue
        }
        let zone = zoneMap[row][column]
        let zoneBit = UInt64(1) << UInt64(zone)
        if (usedZones & zoneBit) != 0 {
          continue
        }
        if row > 0 {
          let prevColumn = placement[row - 1]
          if prevColumn != -1 && abs(prevColumn - column) == 1 {
            continue
          }
        }
        if row + 1 < n {
          let nextColumn = placement[row + 1]
          if nextColumn != -1 && abs(nextColumn - column) == 1 {
            continue
          }
        }
        result.append(column)
        if result.count == limitValue {
          break
        }
      }
      return result
    }
    
    func solve(remainingRows: inout [Int], usedColumns: inout UInt64, usedZones: inout UInt64) -> Bool {
      if remainingRows.isEmpty {
        return true
      }
      
      var bestIndex = -1
      var bestCandidates: [Int] = []
      var bestCount = Int.max
      
      for (index, row) in remainingRows.enumerated() {
        let candidates = candidateColumns(for: row, usedColumns: usedColumns, usedZones: usedZones)
        if candidates.isEmpty {
          return false
        }
        if candidates.count < bestCount {
          bestCount = candidates.count
          bestIndex = index
          bestCandidates = candidates
          if bestCount == 1 {
            break
          }
        }
      }
      
      let row = remainingRows.remove(at: bestIndex)
      defer { remainingRows.insert(row, at: bestIndex) }
      
      for column in bestCandidates {
        let zone = zoneMap[row][column]
        let columnBit = UInt64(1) << UInt64(column)
        let zoneBit = UInt64(1) << UInt64(zone)
        placement[row] = column
        usedColumns |= columnBit
        usedZones |= zoneBit
        
        var forwardConsistent = true
        if row > 0, placement[row - 1] == -1 {
          if candidateColumns(for: row - 1, usedColumns: usedColumns, usedZones: usedZones, limit: 1).isEmpty {
            forwardConsistent = false
          }
        }
        if forwardConsistent, row + 1 < n, placement[row + 1] == -1 {
          if candidateColumns(for: row + 1, usedColumns: usedColumns, usedZones: usedZones, limit: 1).isEmpty {
            forwardConsistent = false
          }
        }
        
        if forwardConsistent && solve(remainingRows: &remainingRows, usedColumns: &usedColumns, usedZones: &usedZones) {
          return true
        }
        
        placement[row] = -1
        usedColumns &= ~columnBit
        usedZones &= ~zoneBit
      }
      
      return false
        }
        
    var mutableRows = unresolvedRows
    var mutableColumnsMask = usedColumnsMask
    var mutableZonesMask = usedZonesMask
    return solve(remainingRows: &mutableRows, usedColumns: &mutableColumnsMask, usedZones: &mutableZonesMask) ? placement : nil
  }
  
  func forbiddenCells() -> [[Bool]] {
    guard rowPlacements.contains(where: { $0 != -1 }) else {
      return Array(
        repeating: Array(repeating: false, count: size),
        count: size
      )
    }
    var blocked = Array(
      repeating: Array(repeating: false, count: size),
      count: size
    )
    let diagonalNeighbors = [(-1, -1), (-1, 1), (1, -1), (1, 1)]
    var rowHasQueen = Array(repeating: false, count: size)
    var queenColumnByRow = Array(repeating: -1, count: size)
    var blockedColumns = Array(repeating: false, count: size)
    var blockedZones = Array(repeating: false, count: size)
    
    for row in 0..<size {
      let column = rowPlacements[row]
      guard column != -1 else { continue }
      rowHasQueen[row] = true
      queenColumnByRow[row] = column
      blockedColumns[column] = true
      let zone = zoneMap[row][column]
      blockedZones[zone] = true
      
      for (dr, dc) in diagonalNeighbors {
        let nr = row + dr
        let nc = column + dc
        guard (0..<size).contains(nr), (0..<size).contains(nc) else { continue }
        if rowPlacements[nr] == nc { continue }
        blocked[nr][nc] = true
      }
    }
    
    for row in 0..<size where rowHasQueen[row] {
      let queenColumn = queenColumnByRow[row]
      for column in 0..<size where column != queenColumn {
        blocked[row][column] = true
      }
    }
    
    for column in 0..<size where blockedColumns[column] {
      for row in 0..<size {
        if rowHasQueen[row] && queenColumnByRow[row] == column { continue }
        blocked[row][column] = true
      }
    }
    
    for zone in 0..<size where blockedZones[zone] {
      for position in zoneCellLookup[zone] {
        if rowHasQueen[position.row] && queenColumnByRow[position.row] == position.column { continue }
        blocked[position.row][position.column] = true
      }
    }
    
    for row in 0..<size where rowHasQueen[row] {
      let column = queenColumnByRow[row]
      if column != -1 {
        blocked[row][column] = false
      }
    }
    
    return blocked
  }
  
  private mutating func rebuildCaches() {
    zoneCounts = Array(repeating: 0, count: size)
    zoneCellLookup = Array(repeating: [], count: size)
    for row in 0..<size {
      for column in 0..<size {
        let zone = zoneMap[row][column]
        zoneCounts[zone] += 1
        zoneCellLookup[zone].append(Position(row: row, column: column))
      }
    }
    columnPriorityForRow = (0..<size).map { row in
      (0..<size).sorted { lhs, rhs in
        let zoneL = zoneMap[row][lhs]
        let zoneR = zoneMap[row][rhs]
        if zoneCounts[zoneL] != zoneCounts[zoneR] {
          return zoneCounts[zoneL] < zoneCounts[zoneR]
        }
        return lhs < rhs
      }
    }
  }
  
  private static func makeStructuredZoneMap(n: Int) -> [[Int]] {
    guard n >= 4 else {
      return makeFallbackZoneMap(n: n)
    }
    var map = makeConnectedZoneMap(n: n, numZones: n)
    if Bool.random() {
      map = mirrorHorizontally(map)
    }
    if Bool.random() {
      map = mirrorVertically(map)
    }
    if Bool.random() {
      map = transpose(map)
    }
    map = shuffleZoneIdentifiers(in: map)
    return map
  }
  
  private static func makeConnectedZoneMap(n: Int, numZones: Int) -> [[Int]] {
    precondition(numZones == n, "현재 구현은 색 개수 = 보드 크기(N) 가정")
    var map = Array(repeating: Array(repeating: -1, count: n), count: n)
    var zoneSizes = Array(repeating: 0, count: numZones)
    var targetSizes = Array(repeating: n * n, count: numZones)
    let requiredSmallZones = min(2, numZones)
    let smallIndices = Array(0..<numZones).shuffled().prefix(requiredSmallZones)
    for zone in smallIndices {
      targetSizes[zone] = Bool.random() ? 1 : 2
    }
    if numZones > requiredSmallZones {
      var candidates = Set(0..<numZones)
      for zone in smallIndices {
        candidates.remove(zone)
      }
      if let mediumZone = candidates.randomElement() {
        let mediumSize = n >= 4 ? (Bool.random() ? 3 : 4) : 3
        targetSizes[mediumZone] = mediumSize
      }
    }
    
    var seeds: [(Int, Int)] = []
    var used = Set<Int>()
    func pickUnique() -> (Int, Int) {
      while true {
        let row = Int.random(in: 0..<n)
        let column = Int.random(in: 0..<n)
        let key = row * n + column
        if !used.contains(key) {
          used.insert(key)
          return (row, column)
        }
      }
    }
    for _ in 0..<numZones {
      seeds.append(pickUnique())
    }
    
    let directions = [(1, 0), (-1, 0), (0, 1), (0, -1)]
    var frontiers: [[(Int, Int)]] = Array(repeating: [], count: numZones)
    for zone in 0..<numZones {
      let (seedRow, seedColumn) = seeds[zone]
      map[seedRow][seedColumn] = zone
      zoneSizes[zone] = 1
      var neighbours: [(Int, Int)] = []
      for (dr, dc) in directions {
        let nr = seedRow + dr
        let nc = seedColumn + dc
        if (0..<n).contains(nr), (0..<n).contains(nc), map[nr][nc] == -1 {
          neighbours.append((nr, nc))
        }
      }
      frontiers[zone] = neighbours.shuffled()
    }
    
    var remaining = n * n - numZones
    var zoneIndex = 0
    while remaining > 0 {
      if zoneSizes[zoneIndex] >= targetSizes[zoneIndex] {
        zoneIndex = (zoneIndex + 1) % numZones
        continue
      }
      if frontiers[zoneIndex].isEmpty {
        let recomputed = recomputeFrontier(map: map, zone: zoneIndex, n: n)
        if recomputed.isEmpty {
          targetSizes[zoneIndex] = zoneSizes[zoneIndex]
          zoneIndex = (zoneIndex + 1) % numZones
          continue
        }
        frontiers[zoneIndex] = recomputed.shuffled()
      }
      guard let (row, column) = frontiers[zoneIndex].popLast() else {
        zoneIndex = (zoneIndex + 1) % numZones
        continue
      }
      if map[row][column] != -1 {
        zoneIndex = (zoneIndex + 1) % numZones
        continue
      }
      map[row][column] = zoneIndex
      zoneSizes[zoneIndex] += 1
      remaining -= 1
      for (dr, dc) in directions {
        let nr = row + dr
        let nc = column + dc
        if (0..<n).contains(nr), (0..<n).contains(nc), map[nr][nc] == -1 {
          frontiers[zoneIndex].append((nr, nc))
        }
      }
      zoneIndex = (zoneIndex + 1) % numZones
    }
    return map
  }
  
  private static func mirrorHorizontally(_ map: [[Int]]) -> [[Int]] {
    map.map { Array($0.reversed()) }
  }
  
  private static func mirrorVertically(_ map: [[Int]]) -> [[Int]] {
    Array(map.reversed())
  }
  
  private static func transpose(_ map: [[Int]]) -> [[Int]] {
    guard let firstRow = map.first else { return map }
    var result = Array(
      repeating: Array(repeating: 0, count: map.count),
      count: firstRow.count
    )
    for (r, row) in map.enumerated() {
      for (c, value) in row.enumerated() {
        result[c][r] = value
      }
    }
    return result
  }
  
  private static func shuffleZoneIdentifiers(in map: [[Int]]) -> [[Int]] {
    let size = map.count
    var result = map
    var identifiers = Array(0..<size)
    identifiers.shuffle()
    for row in 0..<size {
      for column in 0..<size {
        let zone = map[row][column]
        if zone >= 0 && zone < identifiers.count {
          result[row][column] = identifiers[zone]
        }
      }
    }
    return result
  }
  
  private static func recomputeFrontier(map: [[Int]], zone: Int, n: Int) -> [(Int, Int)] {
    var frontier: [(Int, Int)] = []
    let directions = [(1, 0), (-1, 0), (0, 1), (0, -1)]
    for row in 0..<n {
      for column in 0..<n where map[row][column] == zone {
        for (dr, dc) in directions {
          let nr = row + dr
          let nc = column + dc
          if (0..<n).contains(nr), (0..<n).contains(nc), map[nr][nc] == -1 {
            frontier.append((nr, nc))
          }
        }
      }
    }
    return frontier
  }
  
  private static func makeFallbackZoneMap(n: Int) -> [[Int]] {
    precondition(n >= 1)
    var map = Array(repeating: Array(repeating: -1, count: n), count: n)
    var zoneSizes = Array(repeating: 0, count: n)
    var targetSizes = Array(repeating: n * n, count: n)
    targetSizes[0] = 1
    if n > 1 { targetSizes[1] = 2 }
    if n > 2 { targetSizes[2] = n >= 5 ? 4 : 3 }
    
    let seeds: [(Int, Int)] = (0..<n).map { index in
      (min(index, n - 1), index)
    }
    let directions = [(1, 0), (-1, 0), (0, 1), (0, -1)]
    var frontiers: [[(Int, Int)]] = Array(repeating: [], count: n)
    
    for zone in 0..<n {
      var (seedRow, seedColumn) = seeds[zone]
      seedRow = min(seedRow, n - 1)
      seedColumn = min(seedColumn, n - 1)
      if map[seedRow][seedColumn] != -1 {
        outer: for row in 0..<n {
          for column in 0..<n where map[row][column] == -1 {
            seedRow = row
            seedColumn = column
            break outer
          }
        }
      }
      map[seedRow][seedColumn] = zone
      zoneSizes[zone] = 1
      for (dr, dc) in directions {
        let nr = seedRow + dr
        let nc = seedColumn + dc
        if (0..<n).contains(nr), (0..<n).contains(nc), map[nr][nc] == -1 {
          frontiers[zone].append((nr, nc))
        }
      }
    }
    
    var remaining = n * n - n
    var zoneIndex = 0
    while remaining > 0 {
      if zoneSizes[zoneIndex] >= targetSizes[zoneIndex] {
        zoneIndex = (zoneIndex + 1) % n
        continue
      }
      if frontiers[zoneIndex].isEmpty {
        let recomputed = recomputeFrontier(map: map, zone: zoneIndex, n: n)
        if recomputed.isEmpty {
          zoneIndex = (zoneIndex + 1) % n
          continue
        }
        frontiers[zoneIndex] = recomputed
      }
      let (row, column) = frontiers[zoneIndex].removeFirst()
      if map[row][column] != -1 {
        continue
      }
      map[row][column] = zoneIndex
      zoneSizes[zoneIndex] += 1
      remaining -= 1
      for (dr, dc) in directions {
        let nr = row + dr
        let nc = column + dc
        if (0..<n).contains(nr), (0..<n).contains(nc), map[nr][nc] == -1 {
          frontiers[zoneIndex].append((nr, nc))
        }
      }
      zoneIndex = (zoneIndex + 1) % n
    }
    return map
  }
  
  private static func zoneSizeSummary(in map: [[Int]]) -> (small: Int, medium: Int) {
    var counts: [Int: Int] = [:]
    for row in map {
      for zone in row {
        counts[zone, default: 0] += 1
      }
    }
    let small = counts.values.filter { $0 <= 2 }.count
    let medium = counts.values.filter { (3...4).contains($0) }.count
    return (small, medium)
  }
}

#if DEBUG
extension QueensPuzzleBoard {
  mutating func loadTestingZoneMap(_ map: [[Int]]) {
    precondition(map.count == size, "맵 높이가 보드 크기와 일치해야 합니다.")
    precondition(map.allSatisfy { $0.count == size }, "맵 폭이 보드 크기와 일치해야 합니다.")
    zoneMap = map
    rowPlacements = Array(repeating: -1, count: size)
    marks = Array(
      repeating: Array(repeating: false, count: size),
      count: size
    )
    cachedSolution = nil
    rebuildCaches()
  }
}
#endif

extension QueensPuzzleBoard {
  var placements: [Int] {
    rowPlacements
  }
  
  var colorZones: [[Int]] {
    zoneMap
  }
  
  var markMap: [[Bool]] {
    marks
  }
}
