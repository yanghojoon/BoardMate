# BoardMate 개발 문서

BoardMate(보드메이트)는 하나의 빈티지 책상에서 주사위·모래시계·토큰을 사용하는 iOS 앱입니다.

- [전체 작업 계획](2026-10-27-001-feat-boardmate-mvp-plan.md)
- [Step 01 환경·검증 기록](Step-01-Verification.md)
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

2026-10-27 기준, Step 01의 앱·SwiftUI 화면·RealityKit 예정 경로 분리와 프로젝트 설정의 정적 검증을 반영했습니다. 지원 범위는 사용자 결정에 따라 iPhone·세로 방향입니다. Xcode·iOS 26 SDK·Simulator를 확인하지 못해 빌드와 기본 화면 실행은 미검증이며, Step 01 전체 완료는 보류합니다. 세 도구의 기능과 3D 장면은 후속 단계에서 구현합니다.

같은 날짜의 사용자 결정으로 임시 도형 제작 후 최종 모델로 교체하는 순서를 변경했습니다. Step 02부터 실제 사용할 RealityKit 주사위·모래시계·토큰의 형태와 기본 빈티지 재질을 만들고, Step 04~06에서 같은 엔티티에 기능과 연출을 연결합니다. Step 07은 표현 조정과 접근성 검수입니다. 원본 PRD 09절의 이전 납품 순서보다 수정된 전체 계획과 Step 문서를 우선합니다.

Xcode에서 `BoardMate.xcodeproj`를 열고 BoardMate 스킴을 선택합니다. iOS 26 SDK를 포함한 Xcode와 iOS 26 이상 시뮬레이터 또는 iPhone이 필요합니다. Bundle Identifier는 `com.yanghojoon.BoardMate`, 프로젝트에 설정된 개발 팀은 `FA464JRW3F`입니다. 실기기 모델·OS는 추후 제공 예정이며, 개발 계정의 App ID 등록·프로비저닝·서명은 아직 검증하지 않았습니다.

문서는 앱 리소스에 포함하지 않습니다. 구현 경로는 모두 프로젝트 루트 `BoardMate/` 기준이며, PRD의 미정 항목은 전체 계획의 정책 표에서 추적합니다.

