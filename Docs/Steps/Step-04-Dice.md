# U4 / Step 04 · 주사위 굴리기

**목표:** 1~10개 D6를 버튼·흔들기로 굴리고 정확한 결과를 유지한다.
**요구사항:** DIC-01~06, A-01·06·09·10.
**선행:** U2·U3. P-02 굴림 중 전환, P-03 개수 변경 정책을 먼저 확정한다.

## 작업

- [ ] 기본 2개와 1~10개 정수 선택 UI를 제공한다.
- [ ] 균등 난수로 각 결과 1~6을 결정하고 회차와 함께 보관한다.
- [ ] Step 02의 아이보리 D6 엔티티에 이동·회전·착지 연출을 연결한다. 눈금과 메시를 별도 임시 모델로 다시 만들지 않는다.
- [ ] 연출 종료 시 모든 주사위를 정해진 최종 눈금 방향으로 배치한다.
- [ ] 일반 UI에서도 개별 결과를 읽을 수 있게 한다.
- [ ] 버튼과 흔들기가 동일한 굴림 진입점·중복 방지 규칙을 사용하도록 한다.
- [ ] UIKit 흔들기 이벤트를 SwiftUI에 연결하고 활성·주사위 선택·카메라 안정·대기 상태에서만 처리한다.
- [ ] 굴리는 중 개수 변경·재굴림을 차단한다.
- [ ] 화면 이탈·앱 비활성으로 완료 콜백이 누락돼도 잠금과 최종 결과가 복구되게 한다.
- [ ] 개수 변경 전의 결과는 확정한 P-03 정책에 따라 새 설정과 구분한다.

## 주요 파일

- 생성: `BoardMate/Features/Dice/DiceControlsView.swift`, `DiceController.swift` — 모두 같은 Dice 폴더
- 수정: `BoardMate/Features/Dice/DiceEntityFactory.swift` — Step 02의 실제 도구 구성에 굴림·최종 자세를 연결
- 생성: `BoardMate/Infrastructure/RandomSource.swift`, `BoardMate/Infrastructure/ShakeInputBridge.swift`
- 수정: `BoardMate/Features/Dice/DiceState.swift`, `BoardMate/App/BoardMateSession.swift`, `BoardMate/Features/Tabletop/TabletopScene.swift`
- 테스트: `BoardMateTests/DiceControllerTests.swift`, `BoardMateUITests/DiceFlowTests.swift`

## 접근 방식

눈금과 회전의 매핑을 하나로 관리한다. 자유 물리 시뮬레이션으로 최종 결과를 결정하지 않는다. 시작 시 결과 생성은 한 번이며, 연출을 다시 표시하더라도 난수를 다시 뽑지 않는다. 선택 변경만으로 마지막 확정 결과가 사라지지 않는다.

## 테스트 시나리오

1. 1·2·10개를 굴림 → 결과 수 일치, 각 값 1~6이다.
2. 테스트 난수로 1~6 각각 지정 → 최종 3D 윗면과 표시 값이 일치한다. 10개에서도 모두 판독한다.
3. 0·-1·1.5·11개 입력 → 적용되지 않는다.
4. 굴림 중 버튼 연타·흔들기 동시 발생 → 결과 생성과 회차 증가가 한 번이다.
5. 타이머·토큰 선택 또는 앱 비활성 중 흔들기 → 굴림이 발생하지 않는다.
6. 굴리는 중 도구 왕복·앱 복귀 → 같은 회차의 결과가 유지되고 조작이 영구 잠기지 않는다.
7. 대기 중 2개→5개 설정 → 이전 결과 표시가 P-03과 일치하고 다음 굴림 결과는 5개다.

**완료 기준:** 단위·UI 테스트 통과, 실제 iPhone 흔들기 범위 검증, 최대 10개의 눈금·결과 일치 확인. 시뮬레이터만으로 흔들기 실기기 검수를 대체하지 않는다.

