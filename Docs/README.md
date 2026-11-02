# BoardMate 개발 문서

BoardMate(보드메이트)는 하나의 빈티지 책상에서 주사위·모래시계·토큰을 사용하는 iOS 앱입니다.

- [전체 작업 계획](2026-10-27-001-feat-boardmate-mvp-plan.md)
- [Step 01 환경·검증 기록](Step-01-Verification.md)
- [Step 02 장면·검증 기록](QA/Tabletop-Scene.md)
- [Step 03 세션 상태·검증 기록](QA/Session-State.md)
- [Step 04 주사위·검증 기록](QA/Dice.md)
- [Step 05 모래시계·검증 기록](QA/Hourglass.md)
- [3D 자산 목록](Assets/Asset-Manifest.md)
- [원본 PRD v0.2](boardgame-tools-prd.html) — 전달받은 HTML을 내용 변경 없이 복사했습니다.
- [Step 01 · 프로젝트와 정책](Steps/Step-01-Project-Foundation.md)
- [Step 02 · 실제 3D 도구와 책상·카메라](Steps/Step-02-Tabletop-Camera.md)
- [Step 03 · 세션 상태](Steps/Step-03-Session-State.md)
- [Step 04 · 주사위](Steps/Step-04-Dice.md)
- [Step 05 · 모래시계](Steps/Step-05-Hourglass.md)
- [Step 06 · 토큰](Steps/Step-06-Tokens.md)
- [Step 07 · 표현 조정과 접근성](Steps/Step-07-Art-Accessibility.md)
- [Step 08 · 통합 검수](Steps/Step-08-MVP-Verification.md)

## 현재 상태

Step 05에서 분·초 설정·시작·리셋, 루트 세션의 시계 기반 만료와 회차별 UIKit 진동, 비활성 복귀 경과 반영과 3D 모래 양을 연결했습니다. P-04·P-05는 계획용 제안을 구현 기준으로 적용했으며 별도 사용자 확정으로 표시하지 않습니다. 자동 검증과 남은 실기기 검수는 [Step 05 기록](QA/Hourglass.md)을 따릅니다. 토큰의 도구별 UI·연출은 Step 06에 남아 있습니다.

Step 04에서 1~10개 주사위 선택·버튼/흔들기 공통 입력·3D 굴림과 최종 눈금 정렬·회차별 중복 차단·비활성 복구를 연결했습니다. P-02·P-03은 계획안대로 사용자 확정했으며 개수 설정과 직전 결과를 구분합니다. 자동 검증과 남은 실기기 흔들기·가독성 검수는 [Step 04 기록](QA/Dice.md)을 따릅니다.

Step 03에서 루트 소유 세션·공통 입력 검증·주사위/시간/토큰 값 상태와 시계·난수·완료 효과 주입 경계를 구현했습니다. 선택·패널 재생성·비활성 복귀에서 상태를 유지하며 새 세션은 기본값으로 초기화합니다. 상태 전이의 기존 검증은 [Step 03 기록](QA/Session-State.md)을 따릅니다.

2026-10-27 기준, Step 01의 앱·SwiftUI 화면·RealityKit 예정 경로 분리와 프로젝트 설정의 정적 검증을 반영했습니다. 지원 범위는 사용자 결정에 따라 iPhone·세로 방향입니다. Xcode 26.2에서 Debug·Release 빌드·정적 분석과 SwiftLint 검사를 통과하고 iPhone 17 Pro / iOS 26.3.1 시뮬레이터에서 기본 화면 실행을 확인했습니다. 실기기 실행 증거는 후속으로 남깁니다. Step 02에서 실제 3D 도구·월넛 책상·선택과 가상 시점 전환을 구현하고 시뮬레이터 검증을 추가했습니다. 굴림·시간·지급 규칙은 후속 단계에서 구현합니다. Step 02 실기기 식별·선택·성능 검수는 남아 있습니다.

같은 날짜의 사용자 결정으로 임시 도형 제작 후 최종 모델로 교체하는 순서를 변경했습니다. Step 02부터 실제 사용할 RealityKit 주사위·모래시계·토큰의 형태와 기본 빈티지 재질을 만들고, Step 04~06에서 같은 엔티티에 기능과 연출을 연결합니다. Step 07은 표현 조정과 접근성 검수입니다. 원본 PRD 09절의 이전 납품 순서보다 수정된 전체 계획과 Step 문서를 우선합니다.

Xcode에서 `BoardMate.xcodeproj`를 열고 BoardMate 스킴을 선택합니다. iOS 26 SDK를 포함한 Xcode와 iOS 26 이상 시뮬레이터 또는 iPhone이 필요합니다. Bundle Identifier는 `com.yanghojoon.BoardMate`, 프로젝트에 설정된 개발 팀은 `FA464JRW3F`입니다. 사용자가 팀·기기 등록 이슈 수정을 완료했습니다. 이번 검증은 시뮬레이터에서 수행했으며 실기기 모델·OS 기록과 실기기 서명·실행 증거는 별도입니다.

문서는 앱 리소스에 포함하지 않습니다. 구현 경로는 모두 프로젝트 루트 `BoardMate/` 기준이며, PRD의 미정 항목은 전체 계획의 정책 표에서 추적합니다.

