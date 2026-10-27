# Step 02 · 책상과 3D 도구 검증

검증일: 2026-10-27. 브랜치: `feat/step-02-tabletop-camera`.

## 구현과 렌더러 선택

RealityKit `RealityView`의 `.virtual` 경로와 `PerspectiveCamera`를 사용한다. 카메라는 3D 장면을 바라보는 가상 시점이다. 실제 촬영·AR 세션·카메라 권한은 사용하지 않는다. 사용자 자유 카메라는 `.realityViewCameraControls(.none)`으로 끄고 책상·세 도구의 고정 시점을 제공한다. 이 경로에서 프로그램 시점 이동과 엔티티 탭이 동작하여 ARView로 바꿀 근거가 없었다.

실제 제품에 사용할 둥근 D6·황동 모래시계·토큰 표본을 기본 메시로 제작했다. [자산 목록](../Assets/Asset-Manifest.md)에 축·치수·제작 방식과 권한을 기록했다. 외부 모델 로딩·의존성·대체 도형은 없다. 토큰 표본은 보유량과 분리되고 초기 보유량은 0으로 표시한다. 선택 충돌 영역은 도구 루트가 소유한다.

선택 상태는 `CameraCoordinator` 한 곳에서 관리한다. 요청 번호가 바뀌면 이전 이동을 중지하고 현재 위치에서 새 시점으로 이동한다. 취소된 대기 작업과 이전 요청의 완료는 최신 선택을 덮지 않는다. `performToolAction`은 이동 중·책상 전체 보기에서 실행을 거부한다. 실제 굴림·타이머·지급 기능은 Step 03~06의 세션 모델에 연결한다.

## 환경과 검증

- Xcode 26.2 (17C52), iOS Simulator 26.2 SDK, Swift 6.
- iPhone 17 Pro 시뮬레이터 / iOS 26.3.1, UUID `0C0205D5-80E2-4BF3-A631-D446F245E61C`.
- Debug·Release 빌드 및 Release 정적 분석 통과. AppIntents 의존성이 없어 메타데이터 추출을 생략한다는 도구 경고만 관찰했다.
- 단위 테스트 **9개 통과**: 연속 선택·이전 완료 무효화·책상 복귀·동작 줄이기·이동 중 실행 차단, D6 여섯 면 눈금/회전, 모래 체적과 범위 제한, 토큰 제거 후 받침 유지.
- UI 테스트 **5개 통과**: 도구별 직접 이동·책상 복귀, 마지막 선택 유지, 동작 줄이기, 실제 3D 도형 탭, 모래 진행률 0·50·100% 화면.
- 시뮬레이터에서는 유리 너머 모래와 주사위 눈금·1/5/10/20/50 표본이 식별된다. 스크린샷은 `Step-02/`에 보존한다.

초기 전체 실행 13개 통과 후 실행 입력 차단 테스트를 추가했다. 최종 변경에서 단위 9개·화면 이동과 모래 검수 UI 2개를 재실행해 모두 통과했고, 바로 이전 실행에서 실제 도형 탭도 재통과했다. SwiftLint strict는 앱·테스트 14개 파일에서 위반 0건이다.

초기 스크린샷의 그림자 줄무늬는 DirectionalLight 깊이 바이어스를 SDK 기본값으로 되돌려 해소했다. 최종 [시각 검수 기록](Step-02/visual-verdict.json)과 [책상](Step-02/overview.png), [주사위](Step-02/dice.png), [토큰](Step-02/tokens.png), 모래 [0%](Step-02/hourglass-progress-0.png)·[50%](Step-02/hourglass-progress-50.png)·[100%](Step-02/hourglass-progress-100.png)를 남겼다.

시뮬레이터 RealityKit 내부 `engine:throttleGhosted.rematerial` 자산 경로 파싱 메시지가 관찰됐다. 앱은 외부 모델을 로드하지 않으며 렌더링·테스트는 성공했다. 해당 메시지를 앱 자산 로딩 실패나 해소된 오류로 단정하지 않는다.

## 전환과 성능 기준

P-08의 후보 범위 0.3~0.5초 중 **0.4초를 구현 후보**로 적용했다. 사용자 확정 성능 기준은 아니다. 동작 줄이기는 즉시 이동한다. 렌더링 장면은 기본 메시와 로컬 생성 재질이며 개별 모래알 물리·외부 자산 로딩이 없다. UI 테스트 소요 시간에는 XCTest의 대기와 접근성 조회가 포함되어 프레임 속도나 순수 전환 지연으로 해석할 수 없다.

**실기기 모델·OS 미제공으로 실기기 가독성·선택·유리 정렬·전환 검수 및 GPU 프레임 속도/메모리 측정은 미완료다.** 시뮬레이터 결과로 60fps를 달성했다고 주장하지 않는다. P-01 검수 iPhone을 정한 뒤 Instruments에서 초기 프레임·메모리와 0.4초 전환을 측정하고 P-08 최종 통과 기준을 고정한다. Step 02의 실기기 완료 조건은 열어 둔다.

## 재현

프로젝트 루트에서 아래 명령을 실행한다.

```sh
export DEVELOPER_DIR=/Users/yanghojoon/Downloads/Xcode.app/Contents/Developer
xcodebuild -project BoardMate.xcodeproj -scheme BoardMate -configuration Debug \
  -destination 'platform=iOS Simulator,id=0C0205D5-80E2-4BF3-A631-D446F245E61C' \
  -derivedDataPath /tmp/BoardMate-Step02-DerivedData CODE_SIGNING_ALLOWED=NO test
xcodebuild -project BoardMate.xcodeproj -scheme BoardMate -configuration Release \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/BoardMate-Step02-Release CODE_SIGNING_ALLOWED=NO build analyze
swiftlint lint --strict --no-cache BoardMate BoardMateTests BoardMateUITests
```

Debug에서만 `--reduce-motion`, `--hourglass-progress 0|0.5|1` 실행 인자로 검수 상태를 주입한다. 이는 실제 시간·세션 규칙을 구현하지 않는다. 로컬 원본 로그는 `/tmp/BoardMate-Step02-*.log`, 테스트 결과는 `/tmp/BoardMate-Step02-Tests.xcresult`, `/tmp/BoardMate-Step02-Final.xcresult`, `/tmp/BoardMate-Step02-Visual.xcresult`다.

## 공식 API 근거

- [Apple · Lights and cameras](https://developer.apple.com/documentation/realitykit/scene-content-lights-and-cameras)
- [Apple · RealityViewCamera](https://developer.apple.com/documentation/realitykit/realityviewcamera)
- [Apple · PerspectiveCamera](https://developer.apple.com/documentation/realitykit/perspectivecamera)
