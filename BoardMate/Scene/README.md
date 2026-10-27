# RealityKit 장면

`EntityMaterials.swift`는 도구에서 공유하는 기본 빈티지 재질을 정의한다. 실제 메시와 하위 엔티티는 `Features/Dice`, `Features/Hourglass`, `Features/Tokens`의 EntityFactory가 만들고 `Features/Tabletop/TabletopScene.swift`에서 책상·조명·선택 충돌 영역·가상 카메라를 조합한다.

SwiftUI 화면과 선택 전환 상태는 `Features/Tabletop`에 있다. 카메라는 촬영 장치가 아닌 비 AR 장면의 가상 시점이다. 도구 세션 데이터는 엔티티나 카메라에 저장하지 않는다.

모든 소스는 프로젝트 Sources에 명시 등록하며 이 문서는 앱 Resources에 포함하지 않는다. 자산 제작 방식은 `Docs/Assets/Asset-Manifest.md`, 검증 결과는 `Docs/QA/Tabletop-Scene.md`에서 추적한다.
