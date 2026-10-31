# Step 05 · 모래시계 검증

작업일: 2026-10-31. 브랜치: `feat/step05-hourglass`.

## 구현 기준

P-04·P-05의 계획용 제안을 이번 구현 기준으로 채택했다. 별도 사용자 정책 확정으로 기록하지 않는다. 분·초 각각 0~59, 합계 1~3599초를 허용하며 기본값은 3분·대기다. 설정 적용과 시작은 별도 동작이고 실행·종료 후에는 리셋해야 시간을 변경할 수 있다. 일시정지는 제공하지 않는다.

비활성·잠금 중 만료는 종료 상태로만 반영하고 복귀 진동을 생략한다. 백그라운드 진동 전달은 보장하지 않는다. 활성 중 다른 도구를 사용하다 만료되어도 실제 UIKit 완료 진동을 회차당 한 번 요청한다. 시스템 설정과 하드웨어에서의 실제 진동 전달은 실기기 검수 항목이다.

## 구현과 경계

- `HourglassController`는 입력 검증과 시작·리셋의 UI 진입점이다. 세션 활성·도구 선택·카메라 안정 조건과 도메인의 상태 조건을 함께 적용한다.
- 종료 기준 시각과 주입된 현재 시각의 차이로 남은 시간을 계산한다. 루트 앱의 기존 250ms 갱신을 재사용하며 도구 패널이나 연출은 시간을 소유하지 않는다. 시각이 역행해도 설정 시간을 초과하거나 모래 진행률이 음수가 되지 않는다.
- `HourglassState.consumedCompletionID`는 완료를 처리한 회차를 기록한다. 비활성 만료도 처리된 회차로 남겨 활성 복귀·중복 갱신에서 진동을 다시 요청하지 않는다. 비활성 전환에서는 먼저 활성 플래그를 내려 전환 경계에서의 늦은 진동을 차단한다.
- 리셋은 종료 시각·회차·완료 처리 기록을 제거하고 설정 시간·대기·초기 모래 양을 복원한다. 지연된 틱은 저장된 과거 회차가 아닌 현재 상태를 읽으므로 새 회차를 과거 종료 시각으로 완료하지 않는다.
- 기존 황동·유리와 모래 엔티티를 재사용한다. 위·아래 모래의 부피가 남은 시간 비율에 비례하고 낙하 줄기는 실행·활성 상태에서만 표시한다. 동작 줄이기는 모래 양을 유지하면서 줄기를 숨긴다. 세션 갱신으로 화면 밖에서도 현재 양을 반영한다.

## 검증

- 환경: Xcode 26.2, Swift 6, iPhone 17 Pro / iOS 26.3.1 시뮬레이터.
- 전체 단위 테스트: XCTest 9개와 Swift Testing 29개 정의, 합계 38개 통과. 신규 모래시계 테스트 6개가 분·초/총합 경계, 원자적 설정, 중복 시작, 실행 중 변경 거부, 도구 왕복, 실행·종료 후 리셋, 새 회차, 활성/비활성/전환 경계 만료, 회차당 완료 소비, 시각 역행, 모래 부피·낙하 표시를 검증한다. 결과 `/tmp/BoardMate-Step05-Final.xcresult`, 로그 `/tmp/BoardMate-Step05-Final.log`의 단위 테스트 절이다.
- 신규 UI 3개 최종 통과: 입력값·0초 오류·설정 적용·리셋, 다른 도구 왕복 후 만료·리셋·재시작, 실행 중 도구 왕복·홈 복귀 후 경과 반영. 결과 `/tmp/BoardMate-Step05-Verified.xcresult`, 로그 `/tmp/BoardMate-Step05-Verified.log`.
- 기존 주사위 UI 3개와 책상·카메라 UI 5개는 최초 회귀 실행에서 모두 통과했다. 결과 `/tmp/BoardMate-Step05-Tests.xcresult`, 로그 `/tmp/BoardMate-Step05-Test.log`. 이 실행 전체는 신규 시간 입력 테스트의 실패를 포함하므로 전체 성공으로 표시하지 않는다.
- 최초 UI 실패에서 가운데 정렬한 숫자 앞에 커서를 놓고 삭제를 입력해 `03`처럼 값이 추가되는 테스트 조작 문제를 확인했다. 숫자 뒤를 탭하고 실제 필드 값을 검증하도록 수정한 뒤 신규 UI 3개를 재통과했다. 입력 필드의 공통 Bool 포커스도 필드별 식별자로 분리했다. 중간 `/tmp/BoardMate-Step05-Final.xcresult` 역시 단위는 성공, UI는 수정 전 커서 조작으로 실패한 기록이다.
- 최종 Release 빌드·정적 분석 성공: `/tmp/BoardMate-Step05-Release.log`. AppIntents 의존성이 없어 메타데이터 추출을 생략하는 기존 경고가 있다.
- SwiftLint strict: 33개 파일, 위반 0건. `/tmp/BoardMate-Step05-Lint.log`. `git diff --check` 통과.
- [대기 00:30](Step-05/hourglass-idle.png), [종료 00:00](Step-05/hourglass-finished.png), [홈 복귀 실행 00:22](Step-05/hourglass-resumed.png)에서 화면 배치와 실제 세션의 남은 시간·모래 양을 확인했다. 0·중간·100%의 부피 비율은 엔티티 테스트로 검증했다. 기존 `--hourglass-progress` 캡처는 모양만 보여주는 DEBUG 표본으로, 시간 일치 증거에 사용하지 않는다.
- 전용 `visual-verdict` 스킬이 설치되어 있지 않아 직접 캡처를 판독하고 [판정 JSON](Step-05/visual-verdict.json)과 `.omx/state/step05/ralph-progress.json`에 기록했다. 실기기 검수 대기 상태를 유지한다.

## 남은 실기기 검수

- 실제 iPhone에서 모래시계 실행 후 다른 도구를 선택한 상태로 만료되면 진동이 한 번 전달되는지, 복귀에서 반복되지 않는지 확인한다.
- 리셋·새 시작 후 다음 회차도 한 번 진동하는지 확인한다.
- 홈·잠금 중 만료 뒤 복귀 시 종료·0초·아래 모래가 표시되고 늦은 진동이 없는지 확인한다.
- 0·중간·100%의 모래 양과 숫자, 실제 기기의 모래 가독성과 프레임 성능을 확인한다.

## 재현

```sh
export DEVELOPER_DIR=/Users/yanghojoon/Downloads/Xcode.app/Contents/Developer
xcodebuild -project BoardMate.xcodeproj -scheme BoardMate -configuration Debug \
  -destination 'platform=iOS Simulator,id=0C0205D5-80E2-4BF3-A631-D446F245E61C' \
  -derivedDataPath /tmp/BoardMate-Step05-DerivedData CODE_SIGNING_ALLOWED=NO \
  -parallel-testing-enabled NO test
xcodebuild -project BoardMate.xcodeproj -scheme BoardMate -configuration Release \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/BoardMate-Step05-Release \
  CODE_SIGNING_ALLOWED=NO build analyze
swiftlint lint --strict --no-cache BoardMate BoardMateTests BoardMateUITests
```
