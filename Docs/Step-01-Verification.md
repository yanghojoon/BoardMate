# Step 01 검증 기록

검증일: 2026-10-27. 브랜치: `feat/step-01-project-foundation`.

## 결과

프로젝트 구조와 설정의 정적 검증은 통과했다. iOS 빌드·기본 화면 실행·실기기 서명은 미검증이므로 Step 01 전체 완료로 판정하지 않는다. 앱 동작은 변경하지 않았고, 별도 단위 테스트는 Step 01 지침에 따라 추가하지 않았다.

| 항목 | 설정 또는 확인 결과 | 판정 |
| --- | --- | --- |
| 지원 기기·방향 | 사용자 확정: iPhone·세로. `TARGETED_DEVICE_FAMILY = 1`, Portrait만 설정 | 설정 확인 |
| 최소 OS·언어 | Debug·Release 모두 iOS 26.0·Swift 6.0 | 설정 확인, 컴파일 미검증 |
| 타깃·Scheme | BoardMate 앱 타깃, 공유 Scheme의 타깃 ID 일치. 실행 Debug·Archive Release | 파일 확인, Xcode 인식 미검증 |
| Bundle Identifier | `com.yanghojoon.BoardMate` | 설정 완료, 계정 등록·고유성 미검증 |
| 개발 팀 | 작업 중 프로젝트에 추가된 `FA464JRW3F` 보존 | 설정 확인, 서명 미검증 |
| 실기기 | 모델·OS 추후 제공 예정 | 선정 대기 |
| SwiftUI·RealityKit 분리 | `App/`, `Features/Tabletop/`, `Scene/` 그룹·실제 경로 일치 | 통과 |
| 문서 리소스 제외 | Docs 및 Scene README는 탐색기 참조만 존재. Resources는 Assets.xcassets만 포함 | 정적 검사 통과 |
| 소스 헤더 | 기존 두 파일의 양호준·10/27/26 유지. 이동 전후 내용 동일 | 통과 |

## 실행 환경

- `xcode-select -p`: `/Library/Developer/CommandLineTools`.
- `swift --version`: Apple Swift 5.8.1, arm64-apple-darwin25.5.0. 프로젝트의 Swift 6 설정과 구분한다.
- `mdfind 'kMDItemCFBundleIdentifier == "com.apple.dt.Xcode"'`: 검색 결과 없음.
- `/Applications`, `~/Applications`, `/Library/Developer`의 제한된 경로 검색에서 Xcode 앱을 발견하지 못했다. 다른 위치의 미색인 설치까지 없다고 단정하지 않는다.
- `xcodebuild -version`: Xcode 필요 오류. **실제 선택한 Xcode 버전 없음**.
- `xcrun simctl list runtimes`: simctl을 찾지 못함. iOS 26 SDK·Simulator 런타임 미확인.
- `security find-identity -v -p codesigning`: 현재 조회에서 유효한 서명 identity 0개.
- 전역 Xcode 개발자 경로는 변경하지 않았다.

## 수행한 검증

| 검사 | 결과 |
| --- | --- |
| `plutil -lint BoardMate.xcodeproj/project.pbxproj` | 통과 |
| 프로젝트 plist를 JSON으로 변환해 그룹 경로·파일 존재·Sources·Resources·Debug/Release 설정 검사 | 통과 |
| 공유 Scheme XML 파싱과 타깃 ID·실행 및 Archive 구성 검사 | 통과 |
| Assets의 Contents.json 파싱 | 통과 |
| 이동한 Swift 소스와 기본 골격 커밋 `b706c29`의 원본 내용 비교 | 두 파일 모두 동일 |
| `swiftc -frontend -parse BoardMate/App/BoardMateApp.swift BoardMate/Features/Tabletop/ContentView.swift` | 통과. Swift 5.8 구문 검사이며 Swift 6 타입 검사·SDK 빌드를 대체하지 않음 |
| `swiftformat --lint --swiftversion 6.0 --cache ignore BoardMate/App/BoardMateApp.swift BoardMate/Features/Tabletop/ContentView.swift` | 통과, 수정 필요 파일 0개 |
| `swiftlint lint --strict --no-cache …` | SourceKit 로딩 실패로 검사 불가. `SOURCEKIT_TOOLCHAIN_PATH=/Library/Developer/CommandLineTools` 지정 후에도 동일 |
| 시뮬레이터 Debug·Release build | 모두 Xcode 필요 오류로 빌드 시작 불가 |
| 기본 화면 실행·스크린샷·정적 분석 | Xcode·Simulator 부재로 미수행 |
| `git diff --check` | 통과 |

빌드 시도 명령은 아래와 같다. 두 구성 모두 소스 컴파일 이전의 도구 환경 오류로 중단됐다.

```sh
xcodebuild -project BoardMate.xcodeproj -scheme BoardMate \
  -configuration Debug -sdk iphonesimulator \
  -derivedDataPath /tmp/BoardMate-Step01-DerivedData CODE_SIGNING_ALLOWED=NO build
xcodebuild -project BoardMate.xcodeproj -scheme BoardMate \
  -configuration Release -sdk iphonesimulator \
  -derivedDataPath /tmp/BoardMate-Step01-DerivedData CODE_SIGNING_ALLOWED=NO build
```

## 환경 준비 후 재개

1. iOS 26 SDK가 포함된 Xcode 설치 경로를 확인한다. 해당 작업에만 `DEVELOPER_DIR=/실제/Xcode.app/Contents/Developer`를 지정하고 `xcodebuild -version`, `xcodebuild -showsdks`, `xcrun simctl list devices available` 결과를 기록한다.
2. `xcodebuild -list -project BoardMate.xcodeproj`로 앱·공유 Scheme 인식을 확인한다. Debug·Release의 `-showBuildSettings`로 iOS 26·Swift 6·iPhone·세로·팀·번들 ID의 최종 적용 값을 확인한다.
3. 위 Debug·Release 빌드를 실행하고 `xcodebuild -project BoardMate.xcodeproj -scheme BoardMate -configuration Debug -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO analyze` 및 SwiftLint를 재실행한다.
4. 사용 가능한 iOS 26 이상 iPhone Simulator를 부팅한다. 빌드한 `BoardMate.app`을 `xcrun simctl install`로 설치하고 `xcrun simctl launch <기기 UUID> com.yanghojoon.BoardMate`로 실행한다. 기본 화면과 Docs의 탐색기 표시를 확인하고 기기·OS·스크린샷 경로를 기록한다.
5. 사용자 제공 실기기 모델·OS를 기록하고, 개발 계정에서 팀·App ID·프로비저닝을 검증한다. 실기기 실행 결과를 기록한 뒤 Step 01의 남은 체크 항목을 갱신한다.

현재 기록은 세 도구의 초기 상태(A-08), 흔들기·진동·3D 성능의 검증 증거가 아니다. 해당 기능 검증은 후속 Step에서 수행한다.
