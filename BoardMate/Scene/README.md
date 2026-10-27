# RealityKit 장면

Step 02에서 책상·카메라·도구 엔티티와 재질을 구현할 경로다. 현재는 장면 구현이 없다.

SwiftUI 앱 진입점은 `../App/`, 화면은 `../Features/`에 둔다. RealityKit 장면 구성은 이 경로에 두어 화면과 분리한다. 세션 상태와 입력 검증은 장면 엔티티가 소유하지 않는다.

이 문서는 Xcode 탐색기에서만 참조하며 앱 Resources에 포함하지 않는다. 장면 소스와 자산을 추가할 때 각각 Sources·Resources 빌드 단계에 명시적으로 등록한다.
