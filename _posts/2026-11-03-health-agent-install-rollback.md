---
title: "[Troubleshooting] Connect Health 에이전트 설치가 마지막 단계에서 실패하고 되돌려질 때"
date: 2026-11-03 14:20:00 +0900
categories: [iam, troubleshooting]
area: 하이브리드 동기화·에이전트
seq: 1
tags: [Troubleshooting, Entra Connect Health, 에이전트, Windows 방화벽, 아웃바운드 차단, 하이브리드 ID]
excerpt: "등록은 성공했는데 서비스 시작에서 시간 초과로 설치가 롤백됨. 원인은 서비스 실행 파일의 아웃바운드 443이 방화벽에 막힌 것이었다"
toc: true
---

Connect Health 에이전트를 설치하는데 서비스와 서버 등록, 연결 테스트까지 통과하고도 마지막 "서비스 시작"에서 시간 초과가 나며 설치 전체가 취소됐습니다. 원인은 서비스 실행 파일이 Windows 방화벽의 아웃바운드 기본 차단에 걸려 인증 토큰을 받지 못한 것이었고, 그 실행 파일에 대한 허용 규칙을 만들자 설치가 끝났습니다.

## 요약

- 등록과 연결 테스트가 통과해도 서비스 실행 파일이 막히면 설치가 롤백됨
- 허용 규칙은 서비스 이름이 아니라 서비스 실행 파일 경로 기준으로 만들어야 적용됨
- 설치 때 연결 테스트가 통과한 것은 임시로 열어 둔 PowerShell 규칙 때문으로 추정됨

> 근거 표기: 조회 = 이 랩에서 직접 읽은 값 · 문서 = Microsoft Learn · 확인 불가 = 시도했지만 확인하지 못한 값(방법·사유 병기). 테넌트 ID·계정·IP는 적지 않았습니다.

---

## 전체 기록

### 1. 증상

랩 서버(sionnote-sync01, Windows Server 2022)는 아웃바운드를 기본 차단하고 프로그램별로만 허용하는 환경입니다. 이 서버에 Microsoft Entra Connect Health 에이전트(버전 4.5.2614.0) 설치 파일을 실행했습니다.

- 설치 중 로그인 후 서비스(AadSyncService)와 서버 등록, 에이전트 자격 증명 저장, 연결 테스트(Test-AzureADConnectHealthConnectivityAsSystem)가 모두 성공으로 기록됨(조회)
- 그 직후 "Failed starting AzureADConnectHealthAgent" 와 시간 초과(TimeoutException)가 나고 약 3분 만에 설치가 "Installation failed"로 끝남(조회)
- 설치가 되돌려져 서버에는 Health 서비스와 Program Files의 설치 폴더가 남지 않았고, 레지스트리의 ADHealthAgent 키는 남아 있었음(조회)

### 2. 원인 및 분석

공식 문서는 Health 에이전트가 설치 중과 실행 중 모두 Health 서비스 엔드포인트에 443 아웃바운드로 연결할 수 있어야 한다고 설명합니다(문서). 기대값은 서비스가 시작될 때 토큰을 받아 하트비트를 보내는 것이었고, 실제로는 토큰 요청이 방화벽에 막혔습니다.

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

#### 시도 1: 서비스 이름 기준 규칙

서비스 실행 파일 경로를 알기 전에 서비스 이름(AzureADConnectHealthAgent)으로 아웃바운드 허용 규칙을 미리 만들었습니다. 같은 오류로 다시 실패했습니다(조회). 서비스 이름 규칙이 적용되지 않은 이유는 확인하지 못했습니다.

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

설치가 끝났고 AzureADConnectHealthAgent 서비스가 Running이 됐습니다. 서비스 추적 로그(ProgramData 아래 AadConnectHealth\Trace)에는 오류 항목이 0건이고 데이터 수신·업로드 결과 처리 기록이 쌓였습니다(조회).

#### 포털에서 본 결과(GUI)

Microsoft Entra 관리 센터에서 Entra ID → **Microsoft Entra Connect 상태**(Connect Health) → **동기화 서비스** → 테넌트 서비스를 엽니다(검색창에 "Connect Health"를 입력해 들어갔습니다). 서버 `SIONNOTE-SYNC01`이 "정상"으로 표시되고, 경고 요약은 활성 0건, 지난 24시간 동안 해결됨 1건, 동기화 오류 0건입니다. 마지막 내보내기는 2026-11-04 오후 1:26입니다(조회, 2026-11-04 13:30경, 테넌트 이름은 가림).

![Connect Health 동기화 서비스: SIONNOTE-SYNC01 정상(GUI)]({{ "/assets/images/2026/11/hp-health-gui-01-overview.png" | relative_url }})

"모든 경고 보기"에는 해결된 경고가 한 건 있습니다. `Health service data is not up to date.`(서버 SIONNOTE-SYNC01), 생성 11월 3일 오전 6:23, 마지막 업데이트 오전 11:41, **해결 오후 2:19**입니다(조회). 경고 해결 시각(14:19)이 허용 규칙을 만들고 설치가 끝난 시점(이 글의 14시대)과 맞아떨어집니다. 다만 경고가 처음 생긴 시각(6:23)의 원인과 해결 원인은 포털이 알려 주지 않습니다(추정: 에이전트가 설치되지 않아 데이터가 오지 않은 기간과 설치 완료 시점의 일치).

![Connect Health 경고: 해결된 경고 1건(GUI)]({{ "/assets/images/2026/11/hp-health-gui-02-alerts.png" | relative_url }})

#### 설치 때 연결 테스트가 통과한 이유

연결 테스트는 설치 프로그램이 PowerShell 프로세스를 통해 실행합니다. 이 서버에는 그때 진단용으로 PowerShell의 443 아웃바운드를 임시 허용한 규칙이 있었기 때문에, 서비스 실행 파일은 막혀 있어도 테스트는 통과했다고 추정합니다(추정: 규칙이 있었다는 것은 조회, 테스트가 PowerShell로 돈다는 점과 인과관계는 직접 증명하지 못함).

</details>

### 3. 결론

설치 마지막 단계의 서비스 시작에서 서비스 실행 파일의 443 아웃바운드가 방화벽에 막힘 → 토큰을 못 받아 하트비트 검증 실패 → 서비스 시작 시간 초과 → 설치 롤백.

확인 불가가 하나 있습니다. 서비스 이름 기준 규칙이 적용되지 않은 이유입니다(시도: 같은 설치를 한 번 더 실행해 같은 오류 확인, 사유: 방화벽 규칙 평가 내부를 볼 수 없음). 이 서버가 포털에서 정상으로 보이는지는 위에서 확인했습니다.

### 4. 권고방안

1. 방화벽이 아웃바운드 기본 차단이면, 설치를 시작하기 전에 설치 폴더의 서비스 실행 파일(Microsoft.Identity.Health.AgentV15.Service.exe)을 프로그램 경로로 지정해 443(필요하면 80)을 허용합니다.
2. 설치 후 서비스 상태와 추적 로그의 오류 수를 확인합니다. 포트 5671(Service Bus)은 최신 에이전트에서는 필요하지 않고 443만 쓰므로, 5671이 차단돼도 오류가 아닙니다(문서, 이번 랩에서도 5671 차단 기록을 봤지만 동작에는 문제가 없었음).
3. 연결 테스트가 통과했다고 서비스까지 통과한다고 믿지 마세요. 테스트를 돌리는 프로세스(PowerShell)와 서비스 실행 파일은 방화벽에서 서로 다른 프로그램입니다.

관련 글: [Connect Sync 설치하고 방화벽 규칙 하나씩 열기]({{ "/iam/connect-sync-install-firewall/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (4건)</summary>

- **문서**: Health 에이전트는 설치 중과 실행 중 Health 서비스 엔드포인트와 443으로 통신해야 하며, 5671은 최신 버전에서 필요 없음
    - 출처: [Install the Microsoft Entra Connect Health agents](https://learn.microsoft.com/entra/identity/hybrid/connect/how-to-connect-health-agent-install#prerequisites), [Hybrid Identity Required Ports and Protocols](https://learn.microsoft.com/entra/identity/hybrid/connect/reference-connect-ports)
- **조회**: 설치 로그(등록 성공, 서비스 시작 시간 초과, 토큰 요청 소켓 오류), MSI 로그(설치 경로), 설치 후 서비스 Running과 추적 로그 오류 0건
    - 출처: sionnote-sync01 (2026-11-03 설치 시도 2회 실패, 3회째 성공)
- **조회**: 방화벽 규칙 `LAB-ConnectHealth-AgentService-TCP80-443` 생성과 설치 성공의 전후 관계
    - 출처: sionnote-sync01 (Get-NetFirewallRule)
- **조회**: Connect Health 포털의 서버 상태(정상), 경고 요약, 해결된 경고 1건의 생성·해결 시각
    - 출처: Microsoft Entra 관리 센터 > Microsoft Entra Connect 상태 > 동기화 서비스 (2026-11-04)

</details>
