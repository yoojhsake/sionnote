---
title: "[Troubleshooting] Connect Health 에이전트 설치가 마지막 단계에서 실패하고 되돌려질 때"
date: 2026-11-03 14:20:00 +0900
last_modified_at: 2026-11-04 22:00:00 +0900
categories: [iam, troubleshooting]
area: 하이브리드 동기화·에이전트
seq: 1
tags: [Troubleshooting, Entra Connect Health, 에이전트, Windows 방화벽, 아웃바운드 차단, 하이브리드 ID]
excerpt: "등록은 성공했는데 서비스 시작에서 시간 초과로 설치가 롤백됨. 서비스 실행 파일의 아웃바운드 443이 방화벽에 막힌 것으로 보이며(추정), 그 실행 파일 경로로 허용 규칙을 만들자 설치가 끝났다"
toc: true
---

Connect Health 에이전트를 설치하는데 서비스와 서버 등록, 연결 테스트까지 통과하고도 마지막 "서비스 시작"에서 시간 초과가 나며 설치 전체가 취소됐습니다. 원인은 서비스 실행 파일이 Windows 방화벽의 아웃바운드 기본 차단에 걸려 인증 토큰을 받지 못한 것으로 판단했고(추정, 3절의 차단 기록 한계 참고), 그 실행 파일에 대한 허용 규칙을 만들자 설치가 끝났습니다.

## 요약

- 등록과 연결 테스트가 통과해도 서비스 실행 파일의 아웃바운드가 막히면 설치가 롤백되는 것으로 판단함(추정, 3절 참고)
- 이 서비스의 SID 유형이 NONE이고(조회) 문서는 NONE이면 서비스 이름으로는 방화벽 규칙을 적용할 수 없다고 안내하므로(문서), 서비스 이름 기준 허용 규칙은 적용되지 않은 것으로 봄. 실행 파일 경로 기준으로 바꾸자 설치가 끝남(추정: 규칙이 무시됐다는 직접 기록은 없음)
- 설치 때 연결 테스트가 통과한 시각에는 PowerShell 아웃바운드를 임시로 허용한 규칙이 있었음(조회: 방화벽 이벤트 로그). 테스트가 PowerShell로 돈다는 점과 연결해 통과 이유로 추정함

> 근거 표기: 조회 = 이 랩에서 직접 읽은 값 · 문서 = Microsoft Learn · 확인 불가 = 시도했지만 확인하지 못한 값(방법·사유 병기). 테넌트 ID·계정·IP는 적지 않았고 테넌트 이름은 가렸습니다. 랩 서버 이름(SIONNOTE-SYNC01 등)은 그대로 보입니다.

---

## 전체 기록

### 1. 증상

랩 서버(sionnote-sync01, Windows Server 2022)는 아웃바운드를 기본 차단하고 프로그램별로만 허용하는 환경입니다. 이 서버에 Microsoft Entra Connect Health 에이전트(버전 4.5.2614.0) 설치 파일을 실행했습니다.

- 설치 중 로그인 후 서비스·서버 등록, 에이전트 자격 증명 저장, 연결 테스트(Test-AzureADConnectHealthConnectivityAsSystem)가 모두 성공으로 기록됨(조회)
- 그 직후 "Failed starting AzureADConnectHealthAgent" 와 시간 초과(TimeoutException)가 나고 약 3분 만에 설치가 "Installation failed"로 끝남(조회)
- 설치가 되돌려져 서버에는 Health 서비스와 Program Files의 설치 폴더가 남지 않았고, 레지스트리의 ADHealthAgent 키는 남아 있었음(조회)

### 2. 원인 및 분석

공식 문서는 Health 에이전트가 설치 중과 실행 중 모두 Health 서비스 엔드포인트에 443 아웃바운드로 연결할 수 있어야 한다고 설명합니다(문서). 기대값은 서비스가 시작될 때 토큰을 받아 하트비트를 보내는 것이었고, 실제로는 토큰 요청이 소켓 오류로 실패했고(조회), 원인은 방화벽 차단으로 판단했습니다(추정, 3절의 차단 기록 한계 참고).

<details markdown="1">
<summary>확인 과정 자세히 보기 (로그 발췌)</summary>

#### 설치 로그에서 본 것

에이전트 서비스는 시작할 때 Health 서비스의 토큰 엔드포인트(oauth2/token)에서 토큰을 받으려 합니다. 이 요청이 아래 오류로 실패했고, 실패가 4회 반복된 뒤 서비스 시작 검사가 "필수 조건 미충족"으로 종료됐습니다(조회).

```text
Get access token from health service API. [Result:(False)]
 SocketException: An attempt was made to access a socket in a way
 forbidden by its access permissions  (대상: 토큰 엔드포인트 443)
HeartbeatValidationSummary: [CriticalError!] ErrorCode: ClientConnectionError
One or more prerequisites of the agent are not met
```

"접근 권한으로 금지된 방식의 소켓 접근"은 Windows 방화벽이 연결을 막을 때 나오는 형태의 오류입니다. 이번 환경은 아웃바운드 기본 차단이므로 맞는 설명이지만, 이 메시지 하나로 방화벽이라고 단정할 수는 없습니다(추정).

#### 이벤트 뷰어에서 본 것(GUI)

**GUI 경로**: 이벤트 뷰어(`eventvwr.msc`) → Windows 로그 → **Application** → 오른쪽 **Filter Current Log…**에서 Event level을 Error로 지정하고 출처 열에서 `AzureADConnectHealthAgent` 행을 봅니다(조회, 2026-11-04). 같은 목록의 Directory Synchronization(ID 906) 오류는 이 글의 주제가 아닙니다.

같은 소스의 오류는 11-03에 00:56:51, **12:56:28**, **13:08:59**로 세 건입니다. 뒤의 두 건이 이 글에서 설치를 두 번 실패한 시각이고, 00:56:51은 Connect Sync 마법사 끝에서 시도한 Health 설치의 오류입니다. 이벤트 내용은 서비스 시작이 실패한 이유를 그대로 보여 줍니다. 필수 조건(하트비트 검증)이 `ClientConnectionError`로 실패했고, 액세스 토큰을 얻지 못했으며, 소켓 접근이 거부(`forbidden by its access permissions`)됐다는 내용입니다. 접속하려던 주소는 가렸습니다.

[![Application 로그: 화면에 보이는 AzureADConnectHealthAgent 오류 2건(12:56, 13:08)과 이벤트 내용(GUI, 00:56 오류는 목록 아래쪽이라 화면에 없음)]({{ "/assets/images/2026/11/hl-eventlog-gui-01-health-agent-errors.png" | relative_url }})]({{ "/assets/images/2026/11/hl-eventlog-gui-01-health-agent-errors.png" | relative_url }}){:target="_blank"}

#### 시도 1: 서비스 이름 기준 규칙

서비스 실행 파일 경로를 알기 전에 서비스 이름(AzureADConnectHealthAgent)으로 아웃바운드 허용 규칙을 미리 만들었습니다. 같은 오류로 다시 실패했습니다(조회: 규칙 생성 11-03 13:06:53, 설치 실패 13:08:59). 규칙이 듣지 않은 이유는 서비스 SID 유형 때문으로 판단합니다(추정: 아래 문서와 조회 결과를 연결한 판단). 문서는 서비스 이름(Apply to this service)으로 방화벽 규칙을 걸려면 서비스의 SID 유형이 RESTRICTED 또는 UNRESTRICTED여야 하고, `sc qsidtype` 결과가 `NONE`이면 그 서비스에는 방화벽 규칙을 적용할 수 없다고 안내합니다(문서). 이 서비스를 직접 조회하니 `NONE`이었습니다(조회, 2026-11-04 18:39. 13:08 이후 다시 설치된 서비스를 읽은 값이며, 같은 설치 프로그램이 만든 서비스라 같은 값이었을 것으로 봅니다. 추정). 비교로 같은 서버의 `AzureADConnectAgentUpdater` 서비스는 `UNRESTRICTED`였습니다.

서비스 SID 유형은 GUI 화면으로 볼 수 있는 곳이 없어 `sc.exe`로 읽었습니다.

```powershell
sc.exe qsidtype AzureADConnectHealthAgent
sc.exe qsidtype AzureADConnectAgentUpdater
```

[![sc qsidtype 결과: AzureADConnectHealthAgent는 NONE, AzureADConnectAgentUpdater는 UNRESTRICTED(PowerShell)]({{ "/assets/images/2026/11/hl-sid-type-none.png" | relative_url }})]({{ "/assets/images/2026/11/hl-sid-type-none.png" | relative_url }}){:target="_blank"}

**사용한 명령 (조회: sync01 PowerShell 입력 이력)** — 서비스 이름 기준 규칙입니다.

```powershell
New-NetFirewallRule -DisplayName 'LAB-ConnectHealth-AgentService-TCP80-443' -Direction Outbound `
  -Service 'AzureADConnectHealthAgent' -Protocol TCP -RemotePort 80,443 -Action Allow -ErrorAction Stop
```

#### 서비스 실행 파일 경로 찾기

설치 로그(MSI 로그)에서 설치 폴더와 서비스 실행 파일 이름을 찾았습니다(조회).

```text
INSTALLDIR = C:\Program Files\Microsoft Azure AD Connect Health Agent\
서비스 실행 파일: Microsoft.Identity.Health.AgentV15.Service.exe
```

#### 시도 2: 프로그램 경로 기준 규칙

위 경로를 프로그램으로 지정한 규칙으로 바꾸고 설치를 다시 실행했습니다. 입력 이력에 서비스 이름 기준 규칙을 지우고 같은 이름으로 프로그램 경로 기준 규칙을 만든 명령이 있습니다(조회).

```powershell
Remove-NetFirewallRule -DisplayName 'LAB-ConnectHealth-AgentService-TCP80-443'
New-NetFirewallRule -DisplayName 'LAB-ConnectHealth-AgentService-TCP80-443' -Direction Outbound `
  -Program 'C:\Program Files\Microsoft Azure AD Connect Health Agent\Microsoft.Identity.Health.AgentV15.Service.exe' `
  -Protocol TCP -RemotePort 80,443 -Action Allow
```

현재 규칙은 프로그램 `Microsoft.Identity.Health.AgentV15.Service.exe`, TCP 80·443, 허용으로 조회됩니다(앞 글의 LAB- 규칙 7개 화면).

방화벽 규칙의 추가·변경·삭제는 이벤트 뷰어의 **Applications and Services Logs → Microsoft → Windows → Windows Firewall With Advanced Security → Firewall**에서 GUI로 볼 수 있습니다(ID 2004 추가, 2005 변경, 2006 삭제). 다만 이 로그의 목록 화면에는 규칙 이름 열이 없어 이벤트를 하나씩 열어야 하므로, 이름과 시각은 PowerShell로 풀어 읽었습니다(조회, 2026-11-04).

```powershell
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Windows Firewall With Advanced Security/Firewall';Id=2004,2005,2006} |
  % { $m=$_.Message -split "`r?`n"; [pscustomobject]@{T=$_.TimeCreated.ToString('MM-dd HH:mm:ss');Id=$_.Id;Rule=((($m | ? {$_ -match 'Rule Name'}) -join '') -replace '\s+',' ' -replace 'Rule Name: ','')} } |
  ? Rule -match 'LAB-|TEMP-' | sort T | ft -Auto

Get-WinEvent -FilterHashtable @{LogName='Application';ProviderName='AzureADConnectHealthAgent'} |
  % { [pscustomobject]@{T=$_.TimeCreated.ToString('MM-dd HH:mm:ss');LevelDisplayName=$_.LevelDisplayName} } | sort T | ft -Auto
```

캡처는 두 조회의 결과를 이어 붙인 것입니다. 위쪽이 방화벽 규칙 이벤트 23건이고, 아래쪽이 Application 로그의 AzureADConnectHealthAgent 이벤트 6건(오류 3건: 00:56:51, 12:56:28, 13:08:59 / 정보 3건: 13:14:38, 14:31:10, 14:31:11)입니다(조회, 2026-11-04). 오류 두 건(12:56·13:08)은 Health용 허용 규칙이 없던 때와 서비스 이름 기준 규칙(13:06:53, 적용 안 됨)을 만든 뒤의 실패입니다. 13:13:26에 같은 이름의 규칙이 삭제(2006)·추가(2004)로 프로그램 경로 기준으로 바뀌었고(같은 초에 기록돼 캡처에서는 추가가 먼저 보이지만, 입력 이력상 순서는 삭제 후 추가입니다), 그 뒤 13:14:38에 정보 이벤트가 남았습니다. 14:31:10·14:31:11의 정보 이벤트는 임시 규칙 삭제(14:31:03) 7초 뒤이며, 이 목록에는 내용이 없어 의미는 판단하지 않습니다.

[![Windows Firewall 규칙 이벤트(2004 추가·2005 변경·2006 삭제)와 AzureADConnectHealthAgent 오류·정보 이벤트의 시간순 목록(PowerShell)]({{ "/assets/images/2026/11/hl-fw-rule-event-timeline.png" | relative_url }})]({{ "/assets/images/2026/11/hl-fw-rule-event-timeline.png" | relative_url }}){:target="_blank"}

이 목록과 Health 에이전트 이벤트를 시간순으로 맞추면 다음과 같습니다(조회).

| 시각(11-03) | 사건 |
|---|---|
| 11:26:14 | `TEMP-DIAG-powershell-443` 추가(이름으로는 PowerShell 443 임시 허용으로 보이며 규칙 내용은 읽지 않음. 11:28:53에 변경(2005), 14:31:03에 삭제) |
| 12:56:28 | Health 에이전트 오류(설치 첫 실패). 이 시각에는 Health용 허용 규칙이 없었음 |
| 13:06:53 | `LAB-ConnectHealth-AgentService-TCP80-443` 추가, **서비스 이름 기준** |
| 13:08:59 | Health 에이전트 오류(같은 오류로 설치 두 번째 실패) |
| 13:13:26 | 같은 이름의 규칙을 삭제하고 다시 추가, **프로그램 경로 기준** |
| 13:14:38 | Health 에이전트 정보 이벤트(설치 성공) |

두 규칙의 조건은 이벤트 내용으로 확인했습니다. 13:06:53 규칙은 Service Name이 `AzureADConnectHealthAgent`이고 Application Path가 비어 있었으며, 13:13:26 규칙은 Application Path가 `C:\Program Files\Microsoft Azure AD Connect Health Agent\Microsoft.Identity.Health.AgentV15.Service.exe`이고 Service Name이 비어 있었습니다(조회).

[![방화벽 이벤트 상세: 13:13:26 규칙은 Application Path 기준, 13:06:53 규칙은 Service Name 기준(PowerShell)]({{ "/assets/images/2026/11/hl-fw-rule-service-vs-path.png" | relative_url }})]({{ "/assets/images/2026/11/hl-fw-rule-service-vs-path.png" | relative_url }}){:target="_blank"}

설치가 끝났고 AzureADConnectHealthAgent 서비스가 Running이 됐습니다. 서비스 추적 로그(ProgramData 아래 AadConnectHealth\Trace)에는 오류 항목이 0건이고 데이터 수신·업로드 결과 처리 기록이 쌓였습니다(조회).

서비스 관리 화면(services.msc)에서도 같은 상태가 보입니다. `Microsoft Entra Connect Health Agent`가 **실행 중 / 자동**으로 표시되고, 같은 서버의 `Microsoft Azure AD Sync`(Connect Sync 엔진)도 실행 중입니다(조회, 서비스 목록의 한 구간만 확대).

[![services.msc: Microsoft Entra Connect Health Agent 실행 중·자동(GUI)]({{ "/assets/images/2026/11/svc-gui-01-azure-ad-sync-health-agent.png" | relative_url }})]({{ "/assets/images/2026/11/svc-gui-01-azure-ad-sync-health-agent.png" | relative_url }}){:target="_blank"}

#### 포털에서 본 결과(GUI)

Microsoft Entra 관리 센터에서 Entra ID → **Microsoft Entra Connect 상태**(Connect Health) → **동기화 서비스** → 테넌트 서비스를 엽니다(검색창에 "Connect Health"를 입력해 들어갔습니다). 서버 `SIONNOTE-SYNC01`이 "정상"으로 표시되고, 경고 요약은 활성 0건, 지난 24시간 동안 해결됨 1건, 동기화 오류 0건입니다. 마지막 내보내기는 2026-11-04 오후 1:26입니다(조회, 2026-11-04 13:30경, 테넌트 이름은 가림).

[![Connect Health 동기화 서비스: SIONNOTE-SYNC01 정상(GUI)]({{ "/assets/images/2026/11/hp-health-gui-01-overview.png" | relative_url }})]({{ "/assets/images/2026/11/hp-health-gui-01-overview.png" | relative_url }}){:target="_blank"}

"모든 경고 보기"에는 해결된 경고가 한 건 있습니다. `Health service data is not up to date.`(서버 SIONNOTE-SYNC01), 생성 11월 3일 오전 6:23, 마지막 업데이트 오전 11:41, **해결 오후 2:19**입니다(조회). 경고 해결 시각(14:19)은 설치 성공(13:14:38)보다 약 1시간 5분 뒤라서, 설치 직후에 바로 해결된 것은 아닙니다. 설치 성공 뒤 데이터가 다시 들어오기 시작한 시점과 관련이 있을 수 있으나 연결할 근거는 확인하지 못했습니다. 다만 경고가 처음 생긴 시각(6:23)의 원인과 해결 원인은 포털이 알려 주지 않습니다(추정: 에이전트 설치 전에는 데이터가 오지 않았다는 점만 근거이고, 14:19라는 시각 자체는 설명하지 못함).

[![Connect Health 경고: 해결된 경고 1건(GUI)]({{ "/assets/images/2026/11/hp-health-gui-02-alerts.png" | relative_url }})]({{ "/assets/images/2026/11/hp-health-gui-02-alerts.png" | relative_url }}){:target="_blank"}

#### 설치 때 연결 테스트가 통과한 이유

연결 테스트는 설치 프로그램이 PowerShell 프로세스를 통해 실행합니다. 방화벽 이벤트 로그에는 이름으로 보아 진단용 PowerShell 허용 규칙(규칙 내용은 읽지 않음)이 있었습니다. `TEMP-DIAG-PowerShell-Out`은 11-03 00:16:33에 추가돼 07:22:17에 삭제됐고, `TEMP-DIAG-powershell-443`은 11:26:14에 추가돼 14:31:03에 삭제됐습니다(조회, 위 표와 캡처). 두 설치 시도(12:56, 13:08)가 모두 이 규칙이 열려 있던 시간대 안이라, 서비스 실행 파일은 막혀 있어도 테스트는 통과했다고 추정합니다(추정: 규칙의 존재와 시각은 조회, 테스트가 PowerShell로 돈다는 점과 연결한 것은 추정).

</details>

### 3. 결론

(추정) 설치 마지막 단계의 서비스 시작에서 서비스 실행 파일의 443 아웃바운드가 방화벽에 막힘 → 토큰을 못 받아 하트비트 검증 실패 → 서비스 시작 시간 초과 → 설치 롤백.

이 판단을 받치는 것은 두 가지입니다. 하나는 오류 문구(토큰 요청 소켓 오류)이고, 다른 하나는 규칙 변경 전후의 결과입니다. 12:56에는 Health용 허용 규칙이 없었고, 13:06:53에 서비스 이름 기준 규칙을 만들었지만 SID 유형이 NONE이라 적용되지 않아 13:08:59에 같은 오류로 실패했으며, 13:13:26에 프로그램 경로 기준으로 바꾸자 13:14:38에 설치가 끝났습니다(조회). 경로를 허용하자 성공했다는 점이 방화벽 원인설과 맞습니다(추정: 시간 순서와 조건 변화는 조회, 인과는 추정).

**확인 불가**: 12:56·13:08 실패 시각에 방화벽이 실제로 차단했다는 기록은 확인하지 못했습니다. 보안 로그 5157(방화벽 차단 감사)을 11-03 시간대별로 집계하니 12시와 13시는 0건이었고, 11시 47건, 14시 112건처럼 앞뒤 시간대에는 기록이 있었습니다(조회, 2026-11-04). 같은 로그의 12:50~13:15 구간에는 로그온 이벤트(4648 58건 등)가 쌓여 있어 로그가 기록되지 않던 시간은 아니었고, 감사 정책 변경 이벤트 4719에서는 Filtering Platform Connection의 감사 변경이 11:17:12에, 실패 감사 해제가 14:31:03에 조회됩니다(조회). 다만 00:56에 이미 5157이 20건 기록돼 있어 11:17:12가 처음 켠 시각은 아니므로, 12:56·13:08의 감사 상태는 11:17:12 이후 14:31:03 이전이라는 점으로 판단합니다(추정). 감사가 켜져 있었다고 보는데도 5157이 없다는 것은 방화벽 차단설에 불리한 정황이며, 같은 소켓 오류를 만드는 다른 원인은 배제하지 못했습니다(추정). 그래서 이 두 실패를 방화벽 차단 로그로 확인할 수는 없습니다. 서비스 실행 파일의 443 차단 기록은 00:56(20건)에만 있고, 14:31:03의 1건은 포트 5671이었습니다(조회). 시도한 방법은 5157 시간대별 집계, 12:50~13:15 이벤트 종류 집계, 4719 감사 정책 변경 조회이며, 막힌 지점은 차단 기록 자체가 존재하지 않는다는 점입니다. 그래서 "차단 기록으로 확인"이라고 쓰지 않고, 규칙 변경 전후의 결과(경로 기준 규칙을 만들자 설치 성공)에 근거한 추정으로만 적습니다. 00:56 차단 20건은 Connect Sync 마법사 끝에서 시도한 Health 설치의 오류 시각(00:56:51)과 맞습니다(추정: 시각 일치).

이 서버는 포털에서 정상으로 보입니다(위 조회).

### 4. 권고방안

1. 방화벽이 아웃바운드 기본 차단이면, 설치를 시작하기 전에 설치 폴더의 서비스 실행 파일(Microsoft.Identity.Health.AgentV15.Service.exe)을 프로그램 경로로 지정해 443(필요하면 80)을 허용합니다.
2. 서비스 이름 기준 규칙을 쓰고 싶다면 먼저 `sc.exe qsidtype <서비스 이름>`을 실행합니다. `NONE`이면 그 서비스에는 방화벽 규칙을 적용할 수 없으므로 프로그램 경로 기준으로 만듭니다.
3. 설치 후 서비스 상태와 추적 로그의 오류 수를 확인합니다. 포트 5671(Service Bus)은 최신 에이전트에서는 필요하지 않고 443만 쓰므로, 5671이 차단돼도 오류가 아닙니다(문서, 이번 랩에서도 5671 차단 기록을 봤지만 동작에는 문제가 없었음).
4. 연결 테스트가 통과했다고 서비스까지 통과한다고 믿지 마세요. 테스트를 돌리는 프로세스(PowerShell)와 서비스 실행 파일은 방화벽에서 서로 다른 프로그램입니다.

관련 글: [Connect Sync 설치하고 방화벽 규칙 하나씩 열기]({{ "/iam/connect-sync-install-firewall/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (7건)</summary>

- **문서**: Health 에이전트는 설치 중과 실행 중 Health 서비스 엔드포인트와 443으로 통신해야 하며, 5671은 최신 버전에서 필요 없음
    - 출처: [Install the Microsoft Entra Connect Health agents](https://learn.microsoft.com/entra/identity/hybrid/connect/how-to-connect-health-agent-install#prerequisites), [Hybrid Identity Required Ports and Protocols](https://learn.microsoft.com/entra/identity/hybrid/connect/reference-connect-ports)
- **조회**: 설치 로그(등록 성공, 서비스 시작 시간 초과, 토큰 요청 소켓 오류), MSI 로그(설치 경로), 설치 후 서비스 Running과 추적 로그 오류 0건
    - 출처: sionnote-sync01 (2026-11-03 직접 설치 2회 실패 후 3회째 성공, 이와 별개로 Connect Sync 마법사 끝의 설치 실패 1회)
- **조회**: 방화벽 규칙 `LAB-ConnectHealth-AgentService-TCP80-443` 생성과 설치 성공의 전후 관계
    - 출처: sionnote-sync01 (PowerShell 입력 이력, Get-WinEvent의 Windows Firewall 이벤트 2004~2006, 현재 규칙 상태는 앞 글의 LAB- 규칙 7개 화면)
- **조회**: Connect Health 포털의 서버 상태(정상), 경고 요약, 해결된 경고 1건의 생성·해결 시각
    - 출처: Microsoft Entra 관리 센터 > Microsoft Entra Connect 상태 > 동기화 서비스 (2026-11-04)
- **조회**: Application 이벤트 로그의 AzureADConnectHealthAgent 오류 3건(11-03 00:56, 12:56, 13:08. GUI 캡처에는 12:56·13:08 두 건)
    - 출처: sionnote-sync01 이벤트 뷰어 (2026-11-04)
- **조회**: Windows Firewall 규칙 이벤트(2004 추가·2005 변경·2006 삭제)의 규칙 이름·시각·조건(서비스 이름 기준/프로그램 경로 기준), 임시 PowerShell 허용 규칙 2개의 생성·삭제 시각, 보안 로그 5157의 11-03 시간대별 건수(12시·13시 0건, 11시 47건, 14시 112건), 12:50~13:15 구간의 이벤트 종류 집계, 감사 정책 변경 4719(11:17:12 감사 변경, 14:31:03 실패 감사 해제)
    - 출처: sionnote-sync01 (PowerShell Get-WinEvent, 2026-11-04)
- **조회·문서**: `AzureADConnectHealthAgent`의 SID 유형이 NONE이고, SID 유형이 NONE인 서비스에는 방화벽 규칙을 적용할 수 없음
    - 출처: sionnote-sync01 (`sc.exe qsidtype`, 2026-11-04), [Configure rules with group policy](https://learn.microsoft.com/windows/security/operating-system-security/network-security/windows-firewall/configure)(Create an inbound program or service rule 절)

</details>
