# Step 04 · 주사위 검증

검증일: 2026-10-31. 구현·단위·UI 검증 완료. 실제 iPhone 검수는 미완료다.

## 확정 정책과 상태

P-02·P-03은 사용자가 확정했으며 후속 피드백으로 개수 선택의 3D 반영 시점을 수정했다. 시작 시 1~6의 균등 난수를 개수만큼 한 번 생성하고 회차 ID·결과·완료 기준 시각을 보관한다. 굴림 중 도구를 전환해도 같은 회차가 완료된다. 대기 중 개수 선택은 책상의 3D 개수를 즉시 변경한다. 이전 결과에 없는 추가 주사위는 임시로 1면을 보여주며 새 난수를 생성하지 않는다. 직전 숫자 결과는 당시 개수로 별도 유지한다.

`DiceController.roll()`이 버튼과 흔들기의 공통 진입점이다. 세션이 활성이고 주사위가 선택되었으며 카메라가 안정된 대기 상태에서만 실행한다. 도메인에서도 굴림 중 재굴림·개수 변경을 거부하며 회차가 다른 완료 요청은 무시한다. 난수 경계는 기존 `SessionEffects.nextDie`로 주입하고 실제 구현은 `RandomSource`의 `Int.random(in: 1...6)`다.

## 연출과 생명주기

Step 02의 아이보리 메시와 여섯 면 눈금을 복제해 최대 5열·2행으로 배치한다. 최종 자세는 기존 `faceNormal`·`orientation(showing:)` 매핑에 회차·인덱스별 수평 방향을 더한다. 사용자 피드백을 반영해 같은 간격의 네 단계 연출을 연속 시간 궤적으로 교체했다. 각 주사위는 서로 독립적인 회전축·회전량·높이·이동량과 0.88~1.18초의 착지 시간을 갖는다. 세 번의 감소하는 포물선 반동과 감속·정렬을 적용하고, 회전한 큐브의 바닥 지지 높이를 계산해 책상 관통을 막는다. 동작 줄이기에서는 최종 자세를 즉시 보여주며 모델의 회차·입력 잠금 규칙을 유지한다.

모델 완료는 RealityKit 콜백에 의존하지 않는다. 루트의 시각 갱신이 1.2초 완료 기준을 반영하고 비활성 전환에서는 현재 회차를 확정한다. 연출 취소·뷰 재생성·활성 복귀는 저장된 결과로 정렬하며 난수를 다시 생성하지 않는다. UIKit 브리지는 활성 입력에서 first responder를 확보하고 비활성·해제 시 반환하며 `.motionShake` 종료만 전달한다.

## 자동 검증

- 첫 실행에서 10개→1개 배치 시 자식 컬렉션을 순회하며 삭제하면 일부 엔티티가 남는 결함을 재현했다. 자식 배열의 스냅샷에서 삭제하도록 수정했으며 회귀 테스트를 유지한다.
- 단위: 기존 XCTest 9개와 Swift Testing 22개 정의, 합계 31개가 통과했다. 신규 테스트 10개 중 개수 테스트는 1·2·10을 매개변수로 실행한다.
- 신규 검증: 1·2·10개 결과·난수 호출 수, 잘못된 개수, 도구·활성·카메라 입력 조건, 중복 호출, 도구 이탈 중 완료 시각, 비활성 복귀·지연 콜백, 설정과 직전 결과 분리, 10개 윗면·눈금 수·간격 및 1개로 축소, 흔들기 이벤트 필터링.
- 환경: Xcode 26.2, iPhone 17 Pro / iOS 26.3.1 시뮬레이터, Swift 6.
- UI 7개 통과: 신규 주사위 2개(1·2·10개 선택과 결과 유지, 굴림 중 전환·홈 복귀), 기존 책상·카메라 5개(왕복, 연속 선택, 동작 줄이기, 실제 형상 탭, 모래 진행 샘플).
- 타이머 틱이 같은 주사위 상태를 반복 발행하지 않는지, 흔들기 responder가 반복 갱신에도 유지되고 비활성 시 반환되는지도 회귀 테스트로 검증했다. 빈 `inputView`로 불필요한 키보드가 나타나는 현상을 차단했다.
- 전체 회귀 결과: `/tmp/BoardMate-Step04-Verified.xcresult`(30개 단위+7개 UI, 모두 통과). 추가 responder 회귀를 포함한 최종 단위 결과: `/tmp/BoardMate-Step04-Completion.xcresult`(31개 단위+2개 주사위 UI, 모두 통과).
- 위 결과의 텍스트 로그는 같은 이름의 `.log` 파일이다. RealityKit 내부 `engine:throttleGhosted.rematerial` 경로 메시지가 기존 Step 02·03과 같이 남지만 테스트는 통과했다.
- 최종 화면 대비 수정 후 주사위 UI 2개 재통과: `/tmp/BoardMate-Step04-Visual.xcresult`, 로그 `/tmp/BoardMate-Step04-Visual.log`.
- 최종 Release 빌드·정적 분석 성공: `/tmp/BoardMate-Step04-Release-Visual.log`. AppIntents 의존성이 없어 메타데이터 추출을 생략한다는 경고가 있다.
- SwiftLint strict: 28개 파일, 위반 0건. 로그 `/tmp/BoardMate-Step04-Lint-Visual.log`. `git diff --check` 통과.
- 시각 판정: [주사위 1개](Step-04/dice-1.png)·[주사위 10개](Step-04/dice-10.png)에서 배치·눈금·결과 일치를 확인했다. 버튼의 어두운 글자가 배경에 가려지는 문제도 밝은 글자로 수정했다. [판정 JSON](Step-04/visual-verdict.json)은 실기기 검수 대기 상태를 유지한다.

## 후속 피드백 검증

- 개수 선택 즉시 실제 3D 엔티티 수가 바뀌고 직전 숫자 결과는 유지되는 회귀 테스트를 추가했다. 새 결과 난수는 굴리기에서만 생성한다.
- 독립 회전·감속·반동·착지 궤적, 최종 윗면, 책상 관통 방지와 10개 간격을 검증했다. 주사위 크기·간격과 카메라 여유를 조정했다.
- 최종 단위 테스트 32개 정의와 주사위 UI 3개 통과: `/tmp/BoardMate-Dice-Motion-Final.xcresult`, 로그 `/tmp/BoardMate-Dice-Motion-Final.log`.
- Release 빌드·정적 분석 통과: `/tmp/BoardMate-Dice-Motion-Final-Release.log`. SwiftLint strict 28개 파일 위반 0건: `/tmp/BoardMate-Dice-Motion-Final-Lint.log`.
- [굴리기 전 10개 선택](Step-04/dice-10-selected.png), [서로 다른 자세로 움직이는 10개](Step-04/dice-10-motion.png), [착지 결과](Step-04/dice-10.png)를 확인했다. 최종 캡처에서 10개가 화면 안에 분리되어 표시되며 착지 윗면과 숫자 결과가 일치한다. 실제 기기에서의 움직임 체감과 성능은 아래 검수 항목으로 남긴다.

## 남은 실기기 검수

- 실제 iPhone에서 주사위 선택·활성·대기일 때만 흔들기로 한 회차를 시작하는지 확인한다. 브리지 단위 테스트는 하드웨어 전달·first responder 통합의 실기기 증거를 대체하지 않는다.
- 1~6 각각의 실제 윗면 가독성과 최대 10개에서 표시 결과·3D 눈금 일치를 확인한다. 자동 테스트는 회전 벡터·눈금 수 매핑을 검증하며 사람의 판독성을 보증하지 않는다.
- 굴림 중 도구 왕복·홈 이동·잠금 복귀를 확인한다. 성능·실기기 선정은 기존 Step 02·08의 미완료 항목과 함께 유지한다.

## 재현

프로젝트 루트에서 실행한다.

```sh
export DEVELOPER_DIR=/Users/yanghojoon/Downloads/Xcode.app/Contents/Developer
xcodebuild -project BoardMate.xcodeproj -scheme BoardMate -configuration Debug \
  -destination 'platform=iOS Simulator,id=0C0205D5-80E2-4BF3-A631-D446F245E61C' \
  -derivedDataPath /tmp/BoardMate-Step04-DerivedData CODE_SIGNING_ALLOWED=NO \
  -only-testing:BoardMateTests -only-testing:BoardMateUITests -parallel-testing-enabled NO test
xcodebuild -project BoardMate.xcodeproj -scheme BoardMate -configuration Release \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/BoardMate-Step04-Release \
  CODE_SIGNING_ALLOWED=NO build analyze
swiftlint lint --strict --no-cache BoardMate BoardMateTests BoardMateUITests
```

공식 구현 참고: [UIKit motionEnded](https://developer.apple.com/documentation/uikit/uiresponder/motionended(_:with:))의 first responder 이벤트 전달 및 [RealityKit Transform](https://developer.apple.com/documentation/realitykit/transform)의 회전·이동 경계를 사용한다.
