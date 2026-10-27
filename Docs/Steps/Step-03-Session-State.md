# U3 / Step 03 · 화면과 분리된 세션 상태

**목표:** 도구 전환과 화면 재생성이 실제 도구 데이터를 초기화하지 않도록 한다.
**요구사항:** COM-02, DIC-04, TIM-02·06, TOK-04·05, A-06·08·11.
**선행:** U1·U2.

## 작업

- [x] 루트 소유 세션 모델에 도구 선택과 주사위·모래시계·토큰 상태를 둔다.
- [x] 초기값: 주사위 2개·아직 굴리지 않음, 모래시계 180초·시작 대기, 토큰 전 단위 0개로 정의한다.
- [x] 주사위 대기/굴림, 타이머 대기/실행/종료의 전이 규칙을 문서화한다.
- [x] 입력은 표시 문자열과 유효 값을 구분하고 숫자 범위 검증을 도메인 경계에서도 적용한다.
- [x] UI·흔들기·장면 완료 이벤트를 같은 MainActor 상태 변경 경로로 모은다. 공통 진입점이며 실제 이벤트 브리지는 Step 04~06에서 연결한다.
- [x] 테스트 시계·난수·진동 대역을 준비할 수 있는 최소 경계를 정한다.
- [x] scenePhase 관찰은 루트에서 연결하고, 비활성 동안 유지할 시각과 상태를 구분한다.
- [x] 기존 테스트 타깃·공유 Scheme에 Swift Testing 공통 상태·전환 테스트를 연결한다.

## 주요 파일

- 생성: `BoardMate/App/BoardMateSession.swift`
- 생성: `BoardMate/App/InputValidation.swift`
- 생성: `BoardMate/Features/Dice/DiceState.swift`
- 생성: `BoardMate/Features/Hourglass/HourglassState.swift`
- 생성: `BoardMate/Features/Tokens/TokenState.swift`
- 생성: `BoardMate/Infrastructure/SessionClock.swift`
- 수정: `BoardMate/App/BoardMateApp.swift`, `BoardMate/Features/Tabletop/ContentView.swift`, `TabletopView.swift`, 프로젝트 (기존 공유 Scheme 사용)
- 테스트: `BoardMateTests/SessionStateTests.swift`, `BoardMateTests/InputValidationTests.swift`

## 접근 방식

SwiftUI 관찰 가능한 상태는 앱의 루트 생명주기에서 생성한다. 각 도구 패널의 등장/퇴장으로 상태를 새로 만들지 않는다. 결과·수량·종료 시각은 모델이 소유하며 3D 장면은 이를 표시한다. 영구 저장소와 화면별 상태 복제는 추가하지 않는다.

## 테스트 시나리오

1. 새 세션 생성 → 2개·180초 대기·토큰 0개다.
2. 각 도구 상태 설정 후 모든 도구 왕복 → 값이 유지된다.
3. 패널 재생성 → 같은 루트 세션을 사용하고 값이 유지된다.
4. 빈 문자열·음수·소수·상한 초과 → 허용하지 않는 입력이 적용되지 않는다. 토큰의 0 허용은 P-07 확정값을 따른다.
5. 비활성·활성 전환 → 같은 세션 객체와 종료 기준 시각을 유지한다.
6. 새 프로세스에 해당하는 새 세션 생성 → 이전 상태를 복원하지 않는다.

**완료 기준:** Swift Testing으로 상태 유지·초기화 경계와 검증 규칙을 재현한다. 기능별 테스트에서 주입 경계를 사용할 수 있고 실제 대기나 애니메이션 완료에 도메인 검증이 의존하지 않는다.

2026-10-27 구현·단위 검증 완료. [상태 전이·입력 경계·검증 기록](../QA/Session-State.md)을 참조한다. P-02~07의 제품 정책은 후속 Step의 결정 사항이며, Step 02 실기기 미완료 항목도 유지한다.

