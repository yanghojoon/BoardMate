# U1 / Step 01 · Xcode 프로젝트와 정책 정리

**목표:** BoardMate를 iOS 26용 기본 앱으로 실행할 수 있는 출발점을 확보한다.
**요구사항:** PRD 02·08절, A-08의 초기 실행 환경.
**선행:** 없음.
**관련 문서:** [전체 계획](../2026-10-27-001-feat-boardmate-mvp-plan.md).

## 작업

- [ ] 기본 프로젝트의 iOS 26·Swift 6·앱 타깃·공유 Scheme 설정을 확인한다.
- [ ] iOS 26 SDK가 포함된 Xcode와 Simulator를 확인하고 실제 선택한 Xcode 버전을 기록한다.
- [ ] P-01 지원 기기·방향을 결정한다. 현 골격의 iPhone 세로 설정은 임시값이다.
- [ ] 실기기 검수 기기를 선정하고 개발 팀·고유 Bundle Identifier를 설정한다.
- [ ] SwiftUI 화면과 RealityKit 장면을 분리하는 디렉터리 구성을 준비한다.
- [ ] Docs가 Xcode 탐색기에 보이고 앱 Resources 빌드 단계에는 들어가지 않는지 확인한다.
- [ ] 새 소스 헤더의 작성자 양호준과 실제 생성일을 적용한다.

## 주요 파일

- 기본 골격: `BoardMate.xcodeproj/project.pbxproj`, `BoardMate.xcodeproj/xcshareddata/xcschemes/BoardMate.xcscheme`
- 기본 소스: `BoardMate/BoardMateApp.swift`, `BoardMate/ContentView.swift`
- 리소스: `BoardMate/Assets.xcassets/`
- 문서: `Docs/README.md`, `Docs/boardgame-tools-prd.html`, 전체 계획과 Step 문서

## 접근 방식과 검증

Apple 기본 SwiftUI App 진입점을 사용한다. 기존 BoardGameBox의 개발 팀·프로젝트 설정은 복사하지 않는다. Xcode의 전역 경로를 바꾸기 전에 설치 위치를 확인하며, 작업별 경로 설정을 우선한다.

순수 골격에는 별도 동작 단위 테스트를 만들지 않는다. iOS 26 시뮬레이터 Debug 빌드와 기본 화면 실행으로 확인한다. Release 빌드 설정도 검증한다. 기능 단위 테스트는 Step 03에서, UI 테스트 타깃은 Step 02에서 추가한다.

**완료 기준:** Xcode에서 프로젝트와 Scheme을 인식하고 기본 화면을 실행할 수 있다. SDK 또는 서명 문제는 구현 오류와 구분해 기록한다. 현재 생성된 파일만으로 이 실행 검증까지 완료되었다고 간주하지 않는다.
