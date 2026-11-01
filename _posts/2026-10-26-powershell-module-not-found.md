---
title: "[Troubleshooting] 문서의 예제 명령이 '모듈 없음'이거나 환경에 따라 접속되지 않음"
date: 2026-10-26 15:40:00 +0900
categories: [m365, troubleshooting]
area: Graph·Cloud Shell·스크립트
seq: 7
tags: [Troubleshooting, PowerShell, Microsoft Graph 모듈, Cloud Shell, AudienceNotSupported, Windows PowerShell 5.1]
excerpt: "문서 예제 명령이 '모듈 없음'이거나 접속되지 않을 때, 모듈·연결·권한 순서로 나눠 원인 세 가지를 모두 풀었습니다"
toc: true
---

문서에 있는 예제 명령을 그대로 붙여 넣었는데 '모듈 없음'이 나오거나 접속이 되지 않았습니다. 모듈, 연결, 권한 순서로 나눠 보니 원인은 하위 모듈, Cloud Shell의 Azure 토큰, 서비스별 연결 누락 세 가지였고 모두 풀어 값을 읽었습니다.

## 요약

- 문서 예제 명령이 그대로는 실행되지 않음. (1) 모듈, (2) 연결, (3) 권한 순서로 나눔
- 원인은 셋. 별도 하위 모듈 필요, Cloud Shell의 Azure 토큰으로는 서비스 PowerShell 접속 불가, 서비스별 연결 누락
- 모듈 명시 또는 REST 조회, 내 PC의 Windows PowerShell 5.1에서 직접 로그인, 서비스별 연결 명령 실행으로 해결
- 세 가지 모두 값을 읽음(조회)

> 근거 표기: 조회 = 이 테넌트에서 직접 읽은 값, 문서 = Microsoft Learn, 확인 불가 = 시도했지만 확인하지 못한 값(방법·사유 병기). 테넌트 ID, 도메인, 계정, 사용자 이름 등 비공개 정보는 가리거나 게시하지 않았습니다. 조회 값은 화면, PowerShell, Graph에서 읽었습니다.

---

## 전체 기록

### 1. 증상

문서에 있는 예제 명령이 그대로는 실행되지 않았습니다. 상황은 세 가지였습니다.

- `Get-MgServiceAnnouncementMessage` 같은 Graph 명령이 인식되지 않았습니다.
- SharePoint, Teams 관리 명령이 Cloud Shell에서 접속되지 않았습니다.
- Teams, Exchange 명령이 연결 없이 실행되어 실패했습니다.

### 2. 원인과 해결

`Get-MgServiceAnnouncementMessage` 같은 Graph 명령이 인식되지 않은 것은, 해당 명령이 **별도 하위 모듈**(`Microsoft.Graph.Devices.ServiceAnnouncement`)에 있기 때문입니다. `Connect-MgGraph`만으로는 불러지지 않습니다(문서). 모듈을 명시해 설치하고 가져오거나, REST로 직접 조회하면 됩니다(100건 페이징 글의 방식, 아래 관련 글 참고).

SharePoint, Teams 관리 명령은 Cloud Shell의 Azure 토큰으로는 해당 서비스 PowerShell에 접속할 수 없었습니다(`AudienceNotSupported`, 조회). 내 PC의 **Windows PowerShell 5.1**에서 각 모듈로 직접 로그인해 읽었습니다(10/26, 조회). PowerShell 7에서는 호환 모드가 필요하다는 안내가 있습니다(문서, 직접 확인 아님).

Teams, Exchange 명령은 각각 별도 연결이 필요합니다. `Connect-MicrosoftTeams`, `Connect-ExchangeOnline`을 서비스별로 먼저 실행하면 됩니다.

이 과정에서 테넌트 설정은 바꾸지 않았습니다. 모듈 설치는 실행 환경(내 PC)에만 영향을 주므로 원복할 것도 없습니다. 문서의 예제를 쓸 때는 어느 모듈에 속한 명령인지와 어느 환경에서 실행하는지를 함께 기록했습니다.

### 3. 예제가 안 돌 때 정한 순서

**모듈 → 연결 → 권한** 순서로 나눕니다. 이 순서를 지키면 같은 실패를 세 번 다른 방식으로 고치려 하지 않게 됩니다.

Graph 명령이 인식되지 않으면 하위 모듈을 확인하고, 모듈 없이 쓰려면 REST 호출로 대체합니다. 서비스 PowerShell은 Cloud Shell 토큰으로 되지 않을 수 있으니 되는 환경(내 PC의 Windows PowerShell 5.1)에서 직접 로그인합니다. 서비스마다 연결 명령이 다르므로 스크립트 맨 앞에 서비스별 연결을 둡니다.

### 4. 확인 과정

<details markdown="1">
<summary>확인 과정 자세히 보기 (그림 2장)</summary>

#### 오류 문구로 구분하기

명령이 안 될 때는 (1) 모듈, (2) 연결, (3) 권한 순서로 나눠 봅니다. 오류 메시지가 서로 달라서 문구만으로도 구분됩니다.

| 오류 문구 | 가리키는 곳 |
|---|---|
| "인식되지 않는다" | 모듈이 없음 |
| "세션이 없다"(`Session is not established`) | 연결이 없음 |
| Forbidden | 권한(토큰 범위·역할) 문제 |

#### 실제로 본 오류

![Get-MgServiceAnnouncementMessage가 인식되지 않는다는 오류와 Teams 세션 미접속 오류]({{ "/assets/images/2026/10/cmdlet-not-recognized-graph.png" | relative_url }})
*그림 1. Cloud Shell 실행 결과. 위 줄: `Get-MgServiceAnnouncementMessage`가 "인식되지 않는다"(모듈 없음). 아래 줄들: `AccessDenied`(토큰 범위 부족), `Session is not established`(연결 없음). 오류 문구가 서로 달라 모듈, 연결, 권한 문제를 구분할 수 있습니다. 줄 앞 항목 번호는 가렸습니다.*

![Get-SPOTenant가 인식되지 않는다는 오류]({{ "/assets/images/2026/10/cmdlet-not-recognized-spo.png" | relative_url }})
*그림 2. 같은 실행의 다른 항목. `Get-SPOTenant`도 모듈이 없는 환경에서는 같은 "인식되지 않는다" 문구가 나왔습니다.*

`AudienceNotSupported` 오류 화면과 내 PC Windows PowerShell 5.1에서 로그인해 읽은 화면은 남아 있는 캡처가 없어 넣지 못했습니다. 본문에는 읽은 값과 결과만 적었습니다.

PowerShell 7에서의 호환 모드 동작은 직접 실행해 보지 않아 **확인 불가**입니다.

- 시도: 문서 확인만
- 막힌 이유: 실행 환경으로 5.1을 사용
- 다음 방법: PowerShell 7에서 같은 명령을 실행해 결과 대조

</details>

### 5. 관련 글

[Cloud Shell 토큰으로 되는 Graph 호출과 안 되는 호출]({{ "/m365/troubleshooting/cloud-shell-graph-token-scope/" | relative_url }}), [Exchange 장치 코드 로그인이 AADSTS530035로 막힘]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }}), [조회 스크립트 결과가 전부 실패로 나올 때]({{ "/m365/troubleshooting/script-all-fail-token-expired/" | relative_url }})

### 6. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (4건)</summary>

- 문서: 메시지 센터 게시물 조회 명령·API
    - 출처: [List serviceAnnouncement messages](https://learn.microsoft.com/graph/api/serviceannouncement-list-messages?view=graph-rest-1.0)
- 조회: Cloud Shell 토큰으로 SharePoint, Teams 접속 시 `AudienceNotSupported`
    - 출처: Cloud Shell
- 조회: 내 PC Windows PowerShell 5.1에서 각 모듈 직접 로그인 후 읽기
    - 출처: 10/26
- 확인 불가: PowerShell 7 호환 모드 동작
    - 시도: 문서 확인. 막힌 이유: 직접 실행하지 않음. 다음 방법: PowerShell 7에서 실행해 대조

</details>
