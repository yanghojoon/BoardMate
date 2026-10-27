# Step 01 검증 기록

검증일: 2026-10-27. 브랜치: `feat/step-01-project-foundation`.

## 결과

프로젝트 구조·설정과 iOS 시뮬레이터 검증을 통과했다. Xcode 26.2에서 Debug·Release 빌드와 정적 분석을 완료하고 iPhone 17 Pro / iOS 26.3.1에서 기본 화면 실행을 확인했다. 사용자 요청에 따라 이번 검증은 시뮬레이터에서 수행했으며 실기기 서명·검수는 별도다. 앱 소스 변경과 별도 단위 테스트 추가는 없다.

| 항목 | 설정 또는 확인 결과 | 판정 |
| --- | --- | --- |
| 지원 기기·방향 | 사용자 확정: iPhone·세로. `TARGETED_DEVICE_FAMILY = 1`, Portrait만 설정 | 설정 확인 |
| 최소 OS·언어 | Debug·Release 모두 iOS 26.0·Swift 6.0 | Debug·Release 빌드 통과 |
| 타깃·Scheme | BoardMate 앱 타깃, 공유 Scheme의 타깃 ID 일치. 실행 Debug·Archive Release | Xcode 인식·실행 확인 |
| Bundle Identifier | `com.yanghojoon.BoardMate` | 설정 완료, 계정 등록·고유성 미검증 |
| 개발 팀 | 작업 중 프로젝트에 추가된 `FA464JRW3F` 보존 | 설정 확인, 서명 미검증 |
| 실기기 | 사용자: 팀·기기 등록 이슈 수정 완료. 이번 요청은 시뮬레이터 확인 | 이번 실행 검증 범위에서 제외 |
| SwiftUI·RealityKit 분리 | `App/`, `Features/Tabletop/`, `Scene/` 그룹·실제 경로 일치 | 통과 |
| 문서 리소스 제외 | Docs 및 Scene README는 탐색기 참조만 존재. Resources는 Assets.xcassets만 포함 | 정적 검사 통과 |
| 소스 헤더 | 기존 두 파일의 양호준·10/27/26 유지. 이동 전후 내용 동일 | 통과 |

## 초기 환경 확인 (경로 발견 전 기록)

- `xcode-select -p`: `/Library/Developer/CommandLineTools`.
- `swift --version`: Apple Swift 5.8.1, arm64-apple-darwin25.5.0. 프로젝트의 Swift 6 설정과 구분한다.
- `mdfind 'kMDItemCFBundleIdentifier == "com.apple.dt.Xcode"'`: 검색 결과 없음.
- `/Applications`, `~/Applications`, `/Library/Developer`의 제한된 경로 검색에서 Xcode 앱을 발견하지 못했다. 다른 위치의 미색인 설치까지 없다고 단정하지 않는다.
- `xcodebuild -version`: Xcode 필요 오류. **실제 선택한 Xcode 버전 없음**.
- `xcrun simctl list runtimes`: simctl을 찾지 못함. iOS 26 SDK·Simulator 런타임 미확인.
- `security find-identity -v -p codesigning`: 현재 조회에서 유효한 서명 identity 0개.
- 전역 Xcode 개발자 경로는 변경하지 않았다.

## 초기 정적 검증

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

## 시뮬레이터 재검증 결과

사용자가 제공한 `/Users/yanghojoon/Downloads/Xcode.app`을 사용했다. 전역 개발자 경로는 유지하고 아래 명령에만 `DEVELOPER_DIR`를 지정했다. 초기 검색·도구 경로 문제는 해소됐다.

| 항목 | 결과 |
| --- | --- |
| Xcode | 26.2, Build 17C52 |
| SDK | iOS / iOS Simulator 26.2 |
| 실행 기기 | iPhone 17 Pro, UUID `0C0205D5-80E2-4BF3-A631-D446F245E61C` |
| 런타임 | simctl 표시 iOS 26.3, 실제 `SIMULATOR_RUNTIME_VERSION` 26.3.1 |
| 프로젝트·공유 Scheme | `xcodebuild -list`에서 BoardMate 타깃·Scheme 인식 |
| Debug·Release 최종 빌드 설정 | iOS 26.0·Swift 6.0·iPhone·Portrait·Team FA464JRW3F·번들 ID 모두 확인 |
| Debug build | `BUILD SUCCEEDED` |
| Release build | `BUILD SUCCEEDED` |
| Debug analyze | `ANALYZE SUCCEEDED` |
| SwiftLint strict | 2개 파일, 위반 0건 |
| 앱 설치·실행 | 성공, `com.yanghojoon.BoardMate: 58553` |
| 화면 | 주사위 아이콘·BoardMate·보드메이트·소개 문구 정상 표시. 아래 스크린샷 확인 |
| 생성된 Info.plist | MinimumOSVersion 26.0, UIDeviceFamily 1, Portrait 확인 |
| 실행 로그 | 앱 실행 상태 running-active-Visible 확인. libFontParser의 시뮬레이터 AppleColorEmoji.ttc 파일 누락 오류 1건 관찰. 화면 표시는 정상이며 관찰 중 앱 크래시 없음 |

[기본 화면 스크린샷](QA/Step-01/iPhone-17-Pro-iOS-26.3.1.png)

빌드 경고는 AppIntents.framework 의존성이 없어 메타데이터 추출을 건너뛴다는 내용이다. 앱에 App Intents 기능은 없으며 빌드는 성공했다. 시뮬레이터 첫 부팅 데이터 이관에 약 3분 17초가 소요됐다. 샌드박스 안에서는 CoreSimulator·SourceKit 접근이 거부되어, 서비스 접근이 가능한 실행 환경에서 재검증했다.

재현 명령 (프로젝트 루트):

```sh
export DEVELOPER_DIR=/Users/yanghojoon/Downloads/Xcode.app/Contents/Developer
xcodebuild -project BoardMate.xcodeproj -scheme BoardMate -configuration Debug \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,id=0C0205D5-80E2-4BF3-A631-D446F245E61C' \
  -derivedDataPath /tmp/BoardMate-Step01-DerivedData CODE_SIGNING_ALLOWED=NO build
# 같은 명령의 configuration을 Release로 바꿔 Release 빌드 확인
# Debug 구성의 마지막 build를 analyze로 바꿔 정적 분석 확인
xcrun simctl bootstatus 0C0205D5-80E2-4BF3-A631-D446F245E61C -b
xcrun simctl install 0C0205D5-80E2-4BF3-A631-D446F245E61C \
  /tmp/BoardMate-Step01-DerivedData/Build/Products/Debug-iphonesimulator/BoardMate.app
xcrun simctl launch 0C0205D5-80E2-4BF3-A631-D446F245E61C com.yanghojoon.BoardMate
swiftlint lint --strict --no-cache BoardMate/App/BoardMateApp.swift BoardMate/Features/Tabletop/ContentView.swift
```

원본 로그는 로컬 임시 파일 `/tmp/BoardMate-Step01-{Debug,Release,Analyze}.log`, `/tmp/BoardMate-Step01-Settings-{Debug,Release}.log`, `/tmp/BoardMate-Step01-App-Errors.log`에 있다. 임시 파일은 환경 정리 시 삭제될 수 있으므로 결과 요약과 스크린샷을 이 저장소에 보존한다. `CODE_SIGNING_ALLOWED=NO`로 수행한 시뮬레이터 검증이므로 실기기 프로비저닝 성공을 의미하지 않는다.

## 초기 재개 절차 (위 재검증으로 1~4의 빌드·실행 수행)

1. iOS 26 SDK가 포함된 Xcode 설치 경로를 확인한다. 해당 작업에만 `DEVELOPER_DIR=/실제/Xcode.app/Contents/Developer`를 지정하고 `xcodebuild -version`, `xcodebuild -showsdks`, `xcrun simctl list devices available` 결과를 기록한다.
2. `xcodebuild -list -project BoardMate.xcodeproj`로 앱·공유 Scheme 인식을 확인한다. Debug·Release의 `-showBuildSettings`로 iOS 26·Swift 6·iPhone·세로·팀·번들 ID의 최종 적용 값을 확인한다.
3. 위 Debug·Release 빌드를 실행하고 `xcodebuild -project BoardMate.xcodeproj -scheme BoardMate -configuration Debug -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO analyze` 및 SwiftLint를 재실행한다.
4. 사용 가능한 iOS 26 이상 iPhone Simulator를 부팅한다. 빌드한 `BoardMate.app`을 `xcrun simctl install`로 설치하고 `xcrun simctl launch <기기 UUID> com.yanghojoon.BoardMate`로 실행한다. 기본 화면과 Docs의 탐색기 표시를 확인하고 기기·OS·스크린샷 경로를 기록한다.
5. 사용자 제공 실기기 모델·OS를 기록하고, 개발 계정에서 팀·App ID·프로비저닝을 검증한다. 실기기 실행 결과를 기록한 뒤 Step 01의 남은 체크 항목을 갱신한다.

현재 기록은 세 도구의 초기 상태(A-08), 흔들기·진동·3D 성능의 검증 증거가 아니다. 해당 기능 검증은 후속 Step에서 수행한다.
