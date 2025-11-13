# Queens

컬러 존을 따라 변형된 N-Queens 퍼즐을 플레이할 수 있는 SwiftUI iOS 앱입니다. 각 행·열뿐 아니라 같은 색상 존에 중복 배치가 불가능하고, 인접한 대각선 칸에도 퀸을 놓을 수 없도록 설계되어 클래식 퍼즐보다 한층 더 전략적인 난이도를 제공합니다.

## 주요 특징
- **동적 존 생성**: 매 게임마다 연결된 색상 존을 생성해 항상 풀 수 있는 새로운 퍼즐을 제공합니다.
- **쉬운 모드(Easy to Play)**: 현재 배치와 규칙을 기반으로 금지된 칸을 표시해 직관적으로 다음 수를 파악할 수 있습니다.
- **힌트 엔진**: 현재 상태와 양립하는 해답을 찾아 한 행씩 자동으로 채우거나 교정해 줍니다.
- **보드 관리**: 4x4~14x14 범위의 크기와 새 게임, 힌트, 초기화 등 주요 액션을 통합 메뉴와 버튼으로 제공하며 상태 메시지로 피드백합니다.
- **테스트 커버리지**: 커스텀 보드 생성, 인접 대각선 제약, 힌트/금지 칸 로직을 검증하는 `Testing` 기반 단위 테스트가 포함되어 있습니다.

## 프로젝트 구조
- `Queens/Views`: SwiftUI 뷰와 시트, 액션 버튼 등 UI 구성 요소.
- `Queens/ViewModels`: `QueensPuzzleViewModel`이 퍼즐 상태, 메시지, Easy 모드 마스크를 관리하고 백그라운드 큐에서 새 보드를 생성합니다.
- `Queens/Models`: `QueensPuzzleBoard`가 존 생성, 유효성 검사, 힌트/금지 칸 계산을 담당하며, `Item`은 SwiftData 예시 모델입니다.
- `Queens/Utilities`: 색상 헬퍼 등 공용 유틸리티.
- `QueensTests`, `QueensUITests`: 단위/UITest 타깃.

## 개발 환경
- Xcode 15 이상 (Swift 5.9, iOS 17 타깃)
- iOS 17 시뮬레이터 또는 실제 기기

## 실행 방법
1. `Queens.xcodeproj`를 Xcode에서 엽니다.
2. `Queens` 앱 타깃을 선택하고 원하는 시뮬레이터(iPhone 15 등)를 지정합니다.
3. `Cmd + R` 로 빌드 후 실행합니다. 메뉴 버튼으로 보드 크기를 바꾸거나 Easy 모드/힌트를 활용해 퍼즐을 풉니다.

## 테스트 실행
```bash
xcodebuild test \
  -project Queens.xcodeproj \
  -scheme Queens \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```
또는 Xcode의 Test (`Cmd + U`) 기능을 사용해 `QueensTests`를 실행할 수 있습니다.

## 기여/유지보수 팁
- `.gitignore`에 포함된 Xcode 사용자 설정(`xcuserdata`, `.vscode` 등)은 개인 환경에 맞춰 자유롭게 수정하되 커밋에서는 제외하세요.
- 새로운 퍼즐 규칙을 추가할 경우 `QueensPuzzleBoard`의 제약 검사 및 `QueensTests`에 대한 단위 테스트를 함께 갱신해 안정성을 확보하세요.
