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

- 예제 명령이 안 된 원인은 하위 모듈, 접속 환경, 연결 누락 세 가지였음
- 오류 문구를 보고 모듈, 연결, 권한 순서로 나눠 확인하면 됨
- PowerShell 7의 호환 모드 동작은 확인 불가

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다. 조회 값은 화면, PowerShell, Graph에서 읽었습니다.

---

## 전체 기록

### 1. 증상

- 사례 1: Graph 명령(`Get-MgServiceAnnouncementMessage`) 인식 안 됨
- 사례 2: SharePoint, Teams 명령이 Cloud Shell에서 접속 안 됨
- 사례 3: Teams, Exchange 명령 실행 실패

### 2. 원인 및 분석

오류 문구로 원인이 갈립니다(Forbidden이면 토큰 범위·역할 문제).

| 사례 | 오류 문구 | 원인 | 푼 방법 |
|---|---|---|---|
| 1 | "인식되지 않는다" | 명령이 하위 모듈 `Microsoft.Graph.Devices.ServiceAnnouncement`에 있어 `Connect-MgGraph`만으로는 안 불러짐(문서) | 하위 모듈 설치, 또는 REST 조회(100건 페이징 글 방식) |
| 2 | `AudienceNotSupported` | Cloud Shell의 Azure 토큰으로는 서비스 PowerShell 접속 불가(조회) | 내 PC Windows PowerShell 5.1에서 각 모듈로 로그인(10/26) |
| 3 | "세션이 없다"(`Session is not established`) | 서비스별 연결 누락 | `Connect-MicrosoftTeams`, `Connect-ExchangeOnline` 먼저 실행 |

<details markdown="1">
<summary>확인 과정 자세히 보기 (그림 2장)</summary>

![Get-MgServiceAnnouncementMessage가 인식되지 않는다는 오류와 Teams 세션 미접속 오류]({{ "/assets/images/2026/10/cmdlet-not-recognized-graph.png" | relative_url }})
*그림 1. Cloud Shell 실행 결과. 위 줄: `Get-MgServiceAnnouncementMessage`가 "인식되지 않는다"(모듈 없음). 아래 줄들: `AccessDenied`(토큰 범위 부족), `Session is not established`(연결 없음). 오류 문구가 서로 달라 모듈, 연결, 권한 문제를 구분할 수 있습니다. 줄 앞 항목 번호는 가렸습니다.*

![Get-SPOTenant가 인식되지 않는다는 오류]({{ "/assets/images/2026/10/cmdlet-not-recognized-spo.png" | relative_url }})
*그림 2. 같은 실행의 다른 항목. `Get-SPOTenant`도 모듈이 없는 환경에서는 같은 "인식되지 않는다" 문구가 나왔습니다.*

`AudienceNotSupported` 오류 화면과 내 PC Windows PowerShell 5.1에서 로그인해 읽은 화면은 남아 있는 캡처가 없어 넣지 못했습니다. 본문에는 읽은 값과 결과만 적었습니다.

</details>

### 3. 결론

`하위 모듈 없음 / Cloud Shell 토큰 / 연결 누락 → 예제가 그대로 안 돎`

세 원인 모두 풀어 값을 읽었습니다(테넌트 설정 변경 없음). PowerShell 7은 Windows PowerShell 호환 기능(`Import-Module -UseWindowsPowerShell`)이 있다는 문서([about_Windows_PowerShell_Compatibility](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_windows_powershell_compatibility))만 봤고, 동작은 확인 불가입니다(막힌 이유: 5.1로 실행 / 다음 방법: 7에서 같은 명령 실행해 대조).

### 4. 권고방안

1. 조치: 모듈 → 연결 → 권한 순서로 나눠 표의 방법을 적용하고, 서비스별 연결은 스크립트 맨 앞에 둡니다.
2. 조치 후 확인: 표의 오류 문구가 더 나오지 않으면 됩니다. 예제에는 모듈과 실행 환경을 함께 적어 둡니다.

관련 글: [Cloud Shell 토큰으로 되는 Graph 호출과 안 되는 호출]({{ "/m365/troubleshooting/cloud-shell-graph-token-scope/" | relative_url }}) · [Exchange 장치 코드 로그인이 AADSTS530035로 막힘]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }}) · [조회 스크립트 결과가 전부 실패로 나올 때]({{ "/m365/troubleshooting/script-all-fail-token-expired/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (4건)</summary>

- 문서: 메시지 센터 게시물 조회 명령·API
    - 출처: [List serviceAnnouncement messages](https://learn.microsoft.com/graph/api/serviceannouncement-list-messages?view=graph-rest-1.0)
- 조회: Cloud Shell 토큰으로 SharePoint, Teams 접속 시 `AudienceNotSupported`
    - 출처: Cloud Shell
- 조회: 내 PC Windows PowerShell 5.1에서 각 모듈 직접 로그인 후 읽기
    - 출처: 10/26
- 확인 불가: PowerShell 7 호환 모드 동작
    - 출처: [about_Windows_PowerShell_Compatibility](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_windows_powershell_compatibility)
    - 시도: 문서 확인. 막힌 이유: 직접 실행하지 않음. 다음 방법: PowerShell 7에서 실행해 대조

</details>
