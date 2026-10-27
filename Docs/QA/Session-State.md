# Step 03 · 세션 상태 검증

검증일: 2026-10-27.

## 상태 소유와 이벤트 경계

`BoardMateApp`의 `@State`가 `BoardMateSession`을 소유하고 `ContentView`와 `TabletopView`에 같은 객체를 전달한다. 기존 `CameraCoordinator`를 세션 내부로 옮겨 선택과 실행 허용 여부를 공유한다. 패널이 재생성되어도 주사위 결과·타이머 종료 시각·단위별 토큰 수량은 바뀌지 않는다. 새 세션은 주사위 2개·미굴림, 모래시계 180초·대기, 다섯 단위 토큰 0개로 시작하며 영구 저장은 없다.

도구 명령은 MainActor의 세션 메서드로 들어온다. 활성 상태·선택 도구·카메라 전환 완료를 확인한 뒤 도메인 값을 변경한다. 향후 버튼과 흔들기는 같은 `rollDice()`를 호출하고, 장면은 발급받은 회차 ID로 `completeDiceRoll(id:)`를 호출한다. 완료는 선택 화면과 무관하게 처리하되 이전 회차의 콜백은 무시한다. 실제 흔들기 브리지와 연출은 Step 04다.

## 전이 규칙

| 상태 | 입력 | 결과 |
| --- | --- | --- |
| 주사위 대기 | 유효 개수 1~10 | 다음 굴림 개수 변경 |
| 주사위 대기 | 굴림 | 난수를 한 번 생성하고 결과·회차 보관, 굴림 상태 |
| 주사위 굴림 | 재굴림·개수 변경 | 거부, 기존 상태 유지 |
| 주사위 굴림 | 현재 회차 완료 | 대기, 결과 유지 |
| 모든 주사위 상태 | 이전 회차 완료 | 무시 |
| 타이머 대기 | 유효한 양수 시간 | 설정 시간·잔여 시간 변경 |
| 타이머 대기 | 시작 | 종료 기준 시각·회차 보관, 실행 상태 |
| 타이머 실행 | 시계 갱신 | 종료 시각과 현재 시각의 차이, 0에서 종료 |
| 타이머 실행·종료 | 리셋 | 회차·종료 시각 제거, 설정 시간·대기 복원 |
| 타이머 실행·종료 | 시작·설정 변경 | 거부, 먼저 리셋 필요 |
| 토큰 | 유효 수량 추가·보유 이내 제거 | 단위별 수량 반영 |
| 모든 모델 | 잘못된 입력 | 오류 반환, 마지막 유효 상태 유지 |

타이머는 루트의 활성 작업에서 갱신하고 `scenePhase` 변화 때 동기화한다. 비활성 때 작업을 취소해도 종료 시각과 회차는 보존한다. 다른 도구로 이동해도 갱신은 유지된다. 테스트는 `SessionClock.now`를 바꾸며 실제 대기를 사용하지 않는다. 난수와 완료 효과는 `SessionEffects`의 MainActor 클로저로 주입한다. 완료 효과는 회차마다 한 번 소비하며 실제 기기 진동 구현은 아직 연결하지 않았다.

## 입력과 미정 정책

표시 문자열은 명령의 입력이며 파싱 성공 전까지 모델에 저장하지 않는다. 빈 문자열·부호·소수·공백·ASCII 이외 숫자·Int 변환 초과를 거부하고 명시된 범위 안의 정수만 사용한다. 도메인 값 타입에서도 수치 검증을 적용한다. 토큰은 합산 오버플로와 보유량 초과를 거부하며 복수 단위 추가를 전부 검증한 뒤 원자적으로 반영한다.

P-02~07은 사용자 확정으로 바꾸지 않았다. 내부 계약은 결과를 보존하고 비활성 만료 시 상태를 동기화하되 늦은 효과를 전달하지 않는 형태다. P-02·03의 최종 전환/개수 변경 표현은 Step 04에서 확정한다. 시간의 제품 상한과 입력 단위는 Step 05, 토큰 제품 상한·빈 값/0·취소 UX는 Step 06에서 확정하고 검증을 보강한다. 현재 시간의 `Int.max`와 토큰의 오버플로 검사는 저장 표현의 안전 경계이며 제품 상한이 아니다. 토큰 추가 API는 이미 파싱된 값을 받으며 빈 문자열을 0으로 처리하지 않는다.

## 검증

- Swift Testing 12개 테스트 통과: 입력 검증 3개(잘못된 문자열 9종·범위 초과 2종 매개변수 포함), 세션 상태 9개.
- 기존 XCTest 단위 테스트 9개 통과: 카메라 전환 5개·엔티티 4개.
- SwiftLint strict: 앱·테스트 22개 파일, 위반 0건.
- 테스트 환경: Xcode 26.2, iPhone 17 Pro / iOS 26.3.1 시뮬레이터.
- 단위 결과: `/tmp/BoardMate-Step03-Tests-2.xcresult`, 로그 `/tmp/BoardMate-Step03-Test-2.log`.
- 기존 UI 회귀 테스트 3개 통과: 도구 직접 왕복·연속 선택의 마지막 요청 유지·동작 줄이기.
- Release 빌드·정적 분석 통과. AppIntents 의존성이 없어 메타데이터 추출을 생략한다는 경고가 있다.
- UI 결과: `/tmp/BoardMate-Step03-UI.xcresult`, 로그 `/tmp/BoardMate-Step03-UI.log`.
- Release 로그: `/tmp/BoardMate-Step03-Release.log`, 린트 로그: `/tmp/BoardMate-Step03-Lint.log`.

최초 빌드에서 새 파일의 Xcode 그룹 참조가 잘못 연결된 문제를 수정한 뒤 위 단위·UI·Release 검증을 통과했다. 단위 실행 중 Step 02에서도 관찰된 RealityKit 내부 `engine:throttleGhosted.rematerial` 경로 파싱 메시지가 남았으며, 엔티티·상태 테스트는 모두 성공했다.

화면 재생성 검증은 같은 세션으로 SwiftUI 뷰 값을 다시 생성해 소유 관계와 값 유지를 검사하는 단위 테스트다. 실제 OS 프로세스 재실행·실기기 진동·흔들기·3D 기능 일치는 이번 검증 범위가 아니다. Step 02의 실기기 검수·성능 기준은 기존 미완료 상태로 유지한다.

## 재현

프로젝트 루트에서 실행한다.

```sh
export DEVELOPER_DIR=/Users/yanghojoon/Downloads/Xcode.app/Contents/Developer
xcodebuild -project BoardMate.xcodeproj -scheme BoardMate -configuration Debug \
  -destination 'platform=iOS Simulator,id=0C0205D5-80E2-4BF3-A631-D446F245E61C' \
  -derivedDataPath /tmp/BoardMate-Step03-DerivedData CODE_SIGNING_ALLOWED=NO \
  -only-testing:BoardMateTests test
xcodebuild -project BoardMate.xcodeproj -scheme BoardMate -configuration Release \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/BoardMate-Step03-Release CODE_SIGNING_ALLOWED=NO build analyze
swiftlint lint --strict --no-cache BoardMate BoardMateTests BoardMateUITests
```
