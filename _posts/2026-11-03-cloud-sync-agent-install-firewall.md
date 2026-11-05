---
title: "[IAM] Cloud Sync 에이전트 설치하고 DNS·방화벽 맞추기"
date: 2026-11-03 08:55:00 +0900
last_modified_at: 2026-11-04 22:00:00 +0900
categories: [iam]
phase: 하이브리드 실습
seq: 5
tags: [IAM, Entra Cloud Sync, 프로비전 에이전트, gMSA, NRPT, 방화벽]
excerpt: "Cloud Sync 에이전트는 마법사와 서비스가 각각 TCP 443을 쓴다. sync01에서 Microsoft 이름은 NAT DNS로, 도메인 이름은 DC로 풀리게 나누고, 막힌 프로그램마다 규칙을 열어 설치를 끝냈다"
toc: true
---

같은 sync01에 Cloud Sync 프로비전 에이전트를 추가로 설치했습니다. Connect Sync와 달리 에이전트는 클라우드가 설정을 내려주는 가벼운 서비스이지만, 방화벽이 기본 차단이면 마법사와 서비스가 각각 막힙니다. 이 글은 설치 마법사의 다섯 페이지, 이름 풀이(DNS) 구성, 막혔을 때 연 규칙을 순서대로 정리합니다.

## 요약

- 에이전트 마법사(`AADConnectProvisioningAgentWizard.exe`)와 서비스(`AADConnectProvisioningAgent.exe`)는 규칙이 따로 필요함
- sync01은 NIC가 둘이라, Microsoft 클라우드 이름은 NAT DNS로 풀리게 이름별 규칙(NRPT)을 둠
- 서비스 계정은 gMSA로 만들며, 도메인 관리자 자격 입력 오류와 Confirm 단계의 일시 오류(등록 호스트의 이름 풀이 실패와 같은 시각)가 한 번씩 있었음

> 근거 표기: 조회 = 이 랩에서 직접 읽은 값 · 문서 = Microsoft Learn · 확인 불가 = 시도했지만 확인하지 못한 값(방법·사유 병기). 테넌트 ID·테넌트 도메인·클라우드 계정(UPN)은 가렸고, 개인 실습용 도메인(sionnote.local)의 계정 이름·장치 이름·호스트 이름은 그대로 보일 수 있습니다.

---

## 전체 기록

### 1. 목표

OU=CloudSync 아래 계정과 컴퓨터를 Entra ID로 올릴 Cloud Sync 에이전트를 sync01에 설치합니다. 포털의 구성(범위 필터, 장치 동기화)은 뒤 글에서 다룹니다.

### 2. 개념

| 구분 | Connect Sync | Cloud Sync |
|---|---|---|
| 설치되는 것 | 동기화 엔진과 설정 DB를 가진 서버 구성요소 | 프로비전 에이전트(가벼운 서비스) |
| 설정을 두는 곳 | 서버 안(마법사·규칙 편집기) | 클라우드(Entra 관리 센터) |
| 서비스 계정 | `NT SERVICE\ADSync` | gMSA(마법사가 생성, 이 랩은 `provAgentgMSA`) |
| 이 랩에서의 설치 버전(조회) | Entra Connect Sync 2.6.92.0 | Provisioning Agent 1.1.2507.0, 업데이트 도구 1.5.4899.0 |

Cloud Sync 에이전트는 **TCP 443**으로 서비스와 통신하고, 인증서 폐기 목록용으로 **80**을 쓰며, 방화벽이 사용자 기준으로 규칙을 적용한다면 네트워크 서비스 계정 트래픽도 열어야 합니다(문서).

### 3. 결과

#### 3-1. 설치 상태(sync01에서 조회)

| 항목 | 값 |
|---|---|
| 서비스 `AADConnectProvisioningAgent` | Running, Automatic |
| 서비스 `AzureADConnectAgentUpdater` | Running, Automatic |
| 방화벽 규칙 | `LAB-CloudSync-AgentWizard-TCP80-443`, `LAB-CloudSync-Agent-Service-TCP80-443`, `LAB-CloudSync-AgentUpdater-TCP80-443` (모두 Outbound·Allow·TCP 80,443) |

#### 3-2. 마법사 다섯 페이지

| 페이지 | 하는 일 | 이 랩에서 입력한 값 |
|---|---|---|
| Welcome | 설치 시나리오 안내, 약관 | 기본값 |
| Connect Microsoft Entra ID | 하이브리드 ID 관리자 계정으로 로그인 | 테넌트 관리자(가림) |
| Configure Service Account | gMSA 생성 또는 기존 gMSA 지정 | **Create gMSA**, 도메인 관리자 자격으로 생성 |
| Connect Active Directory | 도메인 추가 | `sionnote.local` |
| Confirm | 설정 적용 | 완료 화면에 gMSA `sionnote.local\provAgentgMSA` 표시 |

Configure Service Account·Connect Active Directory·Confirm 세 페이지와 완료 화면입니다(2026-11-03 08:35~08:46).

**Configure Service Account**: **Create gMSA**를 선택하고, 도메인 관리자 계정(`SIONNOTE\yadmin`)의 자격으로 gMSA를 만듭니다. 이 자격은 만들 때만 쓰입니다.

[![Configure Service Account: Create gMSA 선택, 도메인 관리자 계정 입력]({{ "/assets/images/2026/11/ca-07-configure-service-account.png" | relative_url }})]({{ "/assets/images/2026/11/ca-07-configure-service-account.png" | relative_url }}){:target="_blank"}

**Connect Active Directory**: 도메인 `sionnote.local`을 지정하고 **Add Directory**를 누르면 아래 "Configured domains"에 추가됩니다.

[![Connect Active Directory: sionnote.local 추가됨]({{ "/assets/images/2026/11/ca-08-connect-ad.png" | relative_url }})]({{ "/assets/images/2026/11/ca-08-connect-ad.png" | relative_url }}){:target="_blank"}

**Confirm**: 적용 전에 설정을 검토하는 화면입니다. AD 쪽은 `sionnote.local`과 서비스 계정 `sionnote.local\provAgentgMSA`, Entra 쪽은 로그인한 계정(가림)이 표시됩니다.

[![Confirm: 적용할 설정 검토(Entra 계정은 가림)]({{ "/assets/images/2026/11/ca-09-confirm.png" | relative_url }})]({{ "/assets/images/2026/11/ca-09-confirm.png" | relative_url }}){:target="_blank"}

[![설치 완료 화면: gMSA와 완료 메시지]({{ "/assets/images/2026/11/ca-06-complete.png" | relative_url }})]({{ "/assets/images/2026/11/ca-06-complete.png" | relative_url }}){:target="_blank"}

#### 3-3. 이름 풀이(DNS) 구성

sync01은 NIC가 둘입니다. lab-internal 쪽 DNS는 DC이고, NAT 쪽 DNS는 NAT 게이트웨이(`NAT_GW`)입니다. DC에는 포워더가 없어서([AD 구성 글]({{ "/iam/ad-domain-build/" | relative_url }})) Microsoft 이름은 DC로는 풀기 어렵습니다(추정: 포워더 부재와 DC의 인터넷 경로 부재). 그래서 Microsoft 클라우드 이름 접미사별로 "이 이름은 NAT DNS에 물어라"는 규칙(NRPT)을 두었습니다.

<details markdown="1">
<summary>원본 캡처 보기 (터미널 화면, 해상도 낮음)</summary>

[![NRPT 규칙과 이름 풀이 결과]({{ "/assets/images/2026/11/ca-02-nrpt-dns.png" | relative_url }})]({{ "/assets/images/2026/11/ca-02-nrpt-dns.png" | relative_url }}){:target="_blank"}

규칙 명령과 현재 규칙 목록은 이 절 아래에 텍스트로 있습니다.

</details>

위 원본 캡처는 1단계 직후 화면입니다. 캡처의 IP 값은 변수 이름 상자(`NAT_GW`·`DC_IP`)로 가렸고, 나머지는 원본 그대로입니다. `login.microsoftonline.com`·`login.windows.net`·`aadcdn.msauth.net`이 공인 주소로, `sionnote-ad01.sionnote.local`이 `DC_IP`로 풀리는 결과가 함께 있습니다. 이 접미사 목록은 Cloud Sync 필수 요건의 URL 목록(`*.msappproxy.net`, `*.microsoftonline.com`, `login.windows.net`, `aadcdn.msftauth.net` 등)과 겹칩니다(문서).

**사용한 명령 (조회: sync01 PowerShell 입력 이력, 관리자 권한)**

입력 이력에는 IP 값을 직접 적었습니다. 게시용으로는 두 값을 변수로 바꿨습니다(표기용 치환). `NAT_GW`는 sync01의 기본 경로 조회 결과이고, `DC_IP`는 [Hyper-V 실습 환경 글]({{ "/iam/hyperv-lab-environment/" | relative_url }})의 주소 계획에서 정한 DC의 IP입니다. 나머지는 입력 그대로입니다.

```powershell
$NatGw = (Get-NetRoute -DestinationPrefix 0.0.0.0/0 | Select-Object -First 1).NextHop
$DcIp  = '<DC_IP>'   # 자기 환경의 DC IP로 바꿔 넣습니다
```

1단계 — Microsoft 클라우드 접미사 11개를 NAT DNS로 보냅니다.

```powershell
$ns = '.microsoftonline.com','.microsoft.com','.windows.net','.msauth.net','.msftauth.net',
      '.msappproxy.net','.msappproxy.com','.windowsazure.com','.live.com',
      '.msftconnecttest.com','.msocsp.com'
foreach ($n in $ns) {
  Add-DnsClientNrptRule -Namespace $n -NameServers $NatGw `
    -Comment 'LAB split DNS: Entra endpoints via egress DNS' | Out-Null
}
Clear-DnsClientCache
Get-DnsClientNrptRule | ft Namespace,NameServers -auto
```

2단계 — 나머지 이름은 모두 NAT DNS로, 내부 AD 영역만 DC로 보냅니다.

```powershell
Add-DnsClientNrptRule -Namespace '.' -NameServers $NatGw `
  -Comment 'LAB split DNS: default (all names) via egress DNS' | Out-Null
Add-DnsClientNrptRule -Namespace '.sionnote.local' -NameServers $DcIp `
  -Comment 'LAB split DNS: internal AD zone via DC' | Out-Null
Get-DnsClientNrptRule | ? { $_.Namespace -in '.','.sionnote.local' } | ft Namespace,NameServers -auto
```

이름이 풀리는지는 `[Net.Dns]::GetHostAddresses('login.microsoftonline.com')`로 확인했습니다.

현재 규칙은 23개입니다(조회, 2026-11-04 `Get-DnsClientNrptRule`).

| 구분 | 접미사 | 질의할 DNS |
|---|---|---|
| 1단계 명령(11개) | `.microsoftonline.com` `.microsoft.com` `.windows.net` `.msauth.net` `.msftauth.net` `.msappproxy.net` `.msappproxy.com` `.windowsazure.com` `.live.com` `.msftconnecttest.com` `.msocsp.com` | `NAT_GW` (NAT) |
| 이후 추가(10개) | `.microsoftonline-p.com` `.servicebus.windows.net` `.msftauthimages.net` `.digicert.com` `.windowsupdate.com` `.azure.com` `.phonefactor.net` `.msecnd.net` `.msft.net` `.msauthimages.net` | `NAT_GW` (NAT) |
| 기본(2단계) | `.` (그 밖의 모든 이름) | `NAT_GW` (NAT) |
| 내부(2단계) | `.sionnote.local` | `DC_IP` (DC) |

현재 규칙 목록을 글꼴을 키워 다시 캡처했습니다(2026-11-04, 23개).

```powershell
Get-DnsClientNrptRule | Sort-Object { $_.Namespace -join ',' } |
  Format-Table @{n='Namespace';e={$_.Namespace -join ','}}, @{n='NameServers';e={$_.NameServers -join ','}} -AutoSize
```

[![현재 NRPT 규칙 23개(글꼴 확대)]({{ "/assets/images/2026/11/cs-nrpt-rules-hires.png" | relative_url }})]({{ "/assets/images/2026/11/cs-nrpt-rules-hires.png" | relative_url }}){:target="_blank"}

이 캡처도 IP 값만 변수 이름 상자로 가렸습니다.

"이후 추가" 10개의 규칙과 값은 위 표대로 조회했습니다.

### 4. 운영 판단

- **두 프로그램이 따로 필요한 이유**: 마법사는 로그인·구성을 하는 동안만, 서비스는 설치 후 계속 클라우드와 통신합니다. 설치가 끝나도 서비스 규칙이 없으면 포털에서 에이전트가 비정상으로 보입니다.
- **gMSA를 쓰는 이유**: 암호를 사람이 관리하지 않는 서비스 계정이라 만료·유출 부담이 없습니다. 만들 때만 도메인 관리자 자격이 필요하고, 이 자격은 설치 중에만 쓰입니다.
- **방화벽은 프로그램 단위**: 이 랩은 프로그램별로 TCP 80·443을 열었습니다. 운영에서는 문서의 URL·IP 범위로 더 좁히거나 프록시를 쓰는 방법을 검토합니다(문서).

### 5. 절차

1. 에이전트 설치 파일(`AADConnectProvisioningAgentSetup.exe`)을 실행해 약관에 동의하고 설치합니다. 설치되면 구성 마법사가 이어서 열립니다(문서).
2. **Connect Microsoft Entra ID**: 하이브리드 ID 관리자 이상 권한의 계정으로 로그인합니다(문서). 로그인 창이 막히면 6절을 봅니다.
3. **Configure Service Account**: Create gMSA를 선택하고 도메인 관리자 자격을 입력합니다.
4. **Connect Active Directory**: 도메인을 추가합니다.
5. **Confirm**: 내용을 확인하고 Confirm을 눌러 적용합니다. 완료 메시지가 나오면 Exit합니다.
6. 포털(Entra ID → Entra Connect → Cloud sync)에서 에이전트가 활성으로 표시되는지 확인합니다(문서). 포털 확인은 뒤 글에서 합니다.

### 6. 막힌 곳

#### 6-1. 로그인 단계: Unhandled exception

Connect Microsoft Entra ID에서 Authenticate를 누르자 "Unhandled exception - An error occurred while sending the request"가 나왔습니다.

[![Connect Microsoft Entra ID 단계의 Unhandled exception]({{ "/assets/images/2026/11/ca-01-entra-error.png" | relative_url }})]({{ "/assets/images/2026/11/ca-01-entra-error.png" | relative_url }}){:target="_blank"}

마법사 프로그램에 대한 아웃바운드 규칙이 없어서였던 것으로 보입니다(추정). 방화벽 차단 집계에서 `aadconnectprovisioningagentwizard.exe`의 TCP 443이 11-03 08:27에 8건 막혀 있었고(조회, 앞 글의 집계 스크립트), 이후 `LAB-CloudSync-AgentWizard-TCP80-443` 규칙이 만들어져 있습니다. 다만 이 오류 화면의 촬영 시각은 캡처에 남아 있지 않고 첫 실행의 로그인 단계 오류 구간(08:19~08:25)에는 차단 기록이 없어서, 그 구간의 원인이 이름 풀이였을 가능성은 배제하지 못했습니다(추정).

#### 6-2. 로그인 창: Internet Explorer 보안 강화 구성

로그인 창이 열리자 "Internet Explorer Enhanced Security Configuration이 `https://aadcdn.msftauth.net`의 콘텐츠를 차단했다"는 창이 떴습니다. 서버의 IE 보안 강화 구성이 켜져 있으면 Entra 로그인 페이지의 리소스가 막힙니다. Microsoft는 IE 보안 강화 구성이 켜져 있으면 `login.microsoftonline.com`, `secure.aadcdn.microsoftonline-p.com`, `login.windows.net`, `aadcdn.msftauth.net` 같은 사이트를 허용하라고 안내합니다(문서: Connect Health 설치 요건).

[![IE 보안 강화 구성이 로그인 리소스를 차단]({{ "/assets/images/2026/11/ca-03-esc-block.png" | relative_url }})]({{ "/assets/images/2026/11/ca-03-esc-block.png" | relative_url }}){:target="_blank"}

어떻게 넘어갔는지는 레지스트리에 남아 있었습니다(조회, sync01 PowerShell). 보안 강화 구성 자체는 켜져 있고(Active Setup `A509B1A7-37EF-4b3f-8CFC-4F3A74704073`, `A509B1A8-37EF-4b3f-8CFC-4F3A74704073`의 `IsInstalled`가 모두 1), 현재 사용자 쪽 `ZoneMap\EscDomains`에 아래 항목이 "신뢰할 수 있는 사이트(2)"로 들어 있습니다. 컴퓨터 전체(HKLM) 쪽에는 같은 항목이 없습니다.

| 도메인 | 프로토콜 | 값(영역) |
|---|---|---|
| `microsoftonline.com` | https | 2 (신뢰할 수 있는 사이트) |
| `aadcdn.microsoftonline-p.com` (`*.aadcdn`) | https | 2 |
| `aadcdn.msftauth.net` | https | 2 |

즉 보안 강화 구성을 끈 것이 아니라, 로그인 창이 막은 사이트를 신뢰할 수 있는 사이트에 추가해서 넘어갔습니다. 문서의 허용 목록과도 같은 방향입니다. 입력 경로는 아래 시각 표와 함께 정리했습니다.

각 항목이 언제 기록됐는지도 레지스트리 키의 마지막 쓰기 시각으로 읽었습니다(조회, 2026-11-04). `microsoftonline.com`과 `*.aadcdn.microsoftonline-p.com`은 11-03 08:18:48, `msftauth.net\aadcdn`은 11-03 08:32:03입니다.

| 항목(EscDomains 아래) | 마지막 쓰기 시각(VM 시간) |
|---|---|
| `microsoftonline-p.com`, `microsoftonline-p.com\*.aadcdn`, `microsoftonline.com` | 11-03 08:18:48 |
| `msftauth.net`, `msftauth.net\aadcdn` | 11-03 08:32:03 |

두 시각을 마법사 로그와 맞춰 보면 이렇습니다. 첫 마법사 실행은 08:18:51에 시작했고 로그인 단계 오류가 08:19~08:25에 이어졌으며, 두 번째 실행(성공)은 08:34:07에 시작했습니다. 첫 세 항목의 08:18:48은 첫 마법사가 시작되기 3초 전이라, 마법사를 열기 직전에 이미 들어가 있었습니다. 두 항목(`msftauth.net`)은 두 실행 사이인 08:32:03에 들어가서 `aadcdn.msftauth.net` 차단 창을 넘긴 시점과 맞습니다. 누가 어떤 화면에서 넣었는지(경고 창의 추가 버튼인지 직접 입력인지)는 기록이 없습니다(확인 불가: 방법 = 레지스트리 키 쓰기 시각 조회, 사유: 키에는 쓰기 시각만 있고 입력 경로는 남지 않음).

GUI로는 인터넷 옵션(`inetcpl.cpl`) → 보안 → **신뢰할 수 있는 사이트** → **사이트**에서 같은 항목을 볼 수 있습니다(조회). 보안 강화 구성이 켜진 서버라서 이 목록에 `https://*.aadcdn.microsoftonline-p.com`, `https://*.microsoftonline.com`, `https://aadcdn.msftauth.net`이 들어 있습니다.

[![신뢰할 수 있는 사이트 목록: https://*.microsoftonline.com과 https://aadcdn.msftauth.net(GUI)]({{ "/assets/images/2026/11/cs-esc-gui-01-trusted-sites.jpg" | relative_url }})]({{ "/assets/images/2026/11/cs-esc-gui-01-trusted-sites.jpg" | relative_url }}){:target="_blank"}

항목을 확인한 명령입니다.

```powershell
foreach ($r in 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains',
               'HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains') {
  "== $r"
  Get-ChildItem $r -Recurse -ea 0 | ForEach-Object {
    $k = $_
    foreach ($n in $k.GetValueNames()) { '{0} {1}={2}' -f $k.Name.Substring($k.Name.IndexOf('ZoneMap')), $n, $k.GetValue($n) }
  }
}
```

#### 6-3. gMSA 자격 확인 오류

Configure Service Account에서 "Error while validating domain admin creds for username: … The user name or password is incorrect"가 나왔습니다. 에이전트 마법사 로그(조회: `C:\ProgramData\Microsoft\Azure AD Connect Provisioning Agent\Trace\trace-wizard-20261103-083407.log`)에도 08:37~08:38 사이 같은 내용(`AuthenticationException: The user name or password is incorrect`)이 7줄 남아 있습니다. 도메인 컨트롤러가 입력한 관리자 계정의 자격을 거부했다는 뜻이고, 자격을 다시 입력하자 다음 단계로 넘어갔습니다. 어떤 입력이 틀렸는지(암호 오타 또는 계정 형식)는 알 수 없습니다(확인 불가: 방법 = 마법사 로그 확인, 사유 = 로그에 입력값이 기록되지 않음).

[![gMSA 단계의 자격 오류]({{ "/assets/images/2026/11/ca-04-gmsa-error.png" | relative_url }})]({{ "/assets/images/2026/11/ca-04-gmsa-error.png" | relative_url }}){:target="_blank"}

#### 6-4. Confirm 단계: unexpected error

Confirm에서 "We encountered an unexpected error when configuring the provisioning agent. Please try again."가 한 번 나왔고, 같은 화면에서 Confirm을 다시 누르자 완료되었습니다.

[![Confirm 단계의 unexpected error]({{ "/assets/images/2026/11/ca-05-confirm-error.png" | relative_url }})]({{ "/assets/images/2026/11/ca-05-confirm-error.png" | relative_url }}){:target="_blank"}

마법사 로그(조회, 위와 같은 파일)로 순서를 확인했습니다.

| 시각(08시) | 로그 내용 |
|---|---|
| 39:52 | Confirm 시작, KDS 루트 키 생성 |
| 39:53~54 | gMSA `provAgentgMSA`(실제 계정명 `pGMSA_…$`) 생성, 서비스 계정을 gMSA로 변경 |
| 39:56 | AD 권한 부여(암호 해시 동기화 복제 권한 등), "Registering agent with AAD for tenant …" |
| 40:09 | **ERROR** `confirmation step ended with an error: System.InvalidOperationException: Index (zero based) must be greater than or equal to zero and less than the size of the argument list.` |
| 42:40 | 다시 Confirm: gMSA가 이미 있어 생성을 건너뜀 |
| 44:25~26 | "Directory resources successfully updated in AAD", "Directory changes applied successfully" |
| 45:24 | "Completed restarting all required services" |

이 오류는 방화벽 차단이 아니라 **이름 풀이 실패**와 맞물려 있었습니다. 마법사 프로그램(`aadconnectprovisioningagentwizard.exe`)의 TCP 443 차단 기록은 08:27이 마지막이고, 서비스(`aadconnectprovisioningagent.exe`)의 차단 기록은 08:45~08:53이라 오류 시각(08:40)보다 뒤입니다(조회). 대신 Windows 이벤트 로그의 Application에 같은 시각의 오류 이벤트가 있습니다.

**GUI 확인 경로**: 이벤트 뷰어(`eventvwr.msc`) → Windows 로그 → **Application** → 오른쪽 **Filter Current Log…**에서 Event level을 Error로 지정하고 출처 열에서 `Azure AD Connect Provisioning Agent` 행을 봅니다(조회, 2026-11-04). 같은 목록의 Directory Synchronization(ID 906) 오류는 이 글의 주제가 아닙니다.

[![Application 로그의 Error 목록: 08:40:09와 08:42:42에 Provisioning Agent 오류(GUI)]({{ "/assets/images/2026/11/ca-eventlog-gui-01-list.png" | relative_url }})]({{ "/assets/images/2026/11/ca-eventlog-gui-01-list.png" | relative_url }}){:target="_blank"}

08:40:09 이벤트를 열면 다음 내용입니다(이벤트 ID 0, 출처 Azure AD Connect Provisioning Agent).

[![08:40:09 이벤트: Connector registration failed, 이름 풀이 실패(GUI)]({{ "/assets/images/2026/11/ca-eventlog-gui-02-registration-error.png" | relative_url }})]({{ "/assets/images/2026/11/ca-eventlog-gui-02-registration-error.png" | relative_url }}){:target="_blank"}

```text
Connector registration failed: Make sure you enabled Application Proxy in the Azure Management Portal.
Error: 'The remote name could not be resolved: 'cwap-registration-asia1.msappproxy.net''
```

정리하면 이렇습니다(조회와 추정을 구분).

- (조회) 마법사 로그의 Confirm 오류(08:40:09)와 이 이벤트가 같은 초에 기록됐습니다. 마법사 로그의 `InvalidOperationException`(인덱스 범위 오류)은 이 등록 실패를 처리하는 과정의 예외로 보입니다(추정: 같은 초라는 점과 예외 내용이 오류 메시지 형식 문제로 보이는 점).
- (조회) 재시도(08:42:40)에도 같은 소스에서 08:42:42에 "remote name could not be resolved" 이벤트가 있었는데, 이번에는 테넌트별 registration 호스트 이름이었습니다. 그런데도 Confirm은 08:45에 완료됐습니다. 즉 이 등록 실패 메시지가 항상 Confirm을 중단시키지는 않았습니다.
- (조회) 지금은 `cwap-registration-asia1.msappproxy.net`이 공인 주소로 풀립니다(`[Net.Dns]::GetHostAddresses`). NRPT에는 `.msappproxy.net`이 NAT DNS로 가는 규칙이 들어 있습니다(위 3-3절).
- (확인 불가) 08:40에 그 이름이 풀리지 않은 이유(NAT DNS의 일시적 응답 실패인지 등)는 알 수 없습니다. 방법 = DNS 클라이언트 운영 로그 조회, 사유 = 이 서버에서 그 로그가 꺼져 있어 당시 질의 기록이 없습니다.

이 결과로 앞 글의 0x80072ee7(이름 풀이 실패)과 같은 계열의 문제가 Cloud Sync 에이전트 등록에서도 한 번 나타난 것입니다. 이름 풀이를 먼저 의심하는 순서가 맞았습니다(추정).

로그를 찾은 명령입니다.

```powershell
$d = 'C:\ProgramData\Microsoft\Azure AD Connect Provisioning Agent\Trace'
Get-Content "$d\trace-wizard-20261103-083407.log" |
  ? { $_ -match '\[(ERRO|WARN|FATL)|xception' } |
  % { if ($_.Length -gt 250) { $_.Substring(0,250) } else { $_ } }
```

이벤트 로그는 PowerShell로도 읽을 수 있습니다.

```powershell
Get-WinEvent -FilterHashtable @{LogName='Application';ProviderName='Azure AD Connect Provisioning Agent';
  StartTime='2026-11-03 08:39:30';EndTime='2026-11-03 08:41:30'} |
  ForEach-Object { $_.TimeCreated.ToString('HH:mm:ss') + ' ' + $_.LevelDisplayName; $_.Message }
```

### 7. 정리·남은 일

- 차단 집계에는 `azureadconnectagentupdater.exe`의 TCP 443 차단이 4건(11-03 00:29~11:02) 있습니다(조회). 00:29는 Cloud Sync 에이전트 설치(08시대)보다 이르므로 4건 전체를 Cloud Sync 업데이트 도구의 기록으로 볼 수 없고, 집계가 파일 이름만 기준이라 어느 설치의 업데이트 도구인지 나누지 않았습니다. `LAB-CloudSync-AgentUpdater-TCP80-443` 규칙은 이후에 만들었습니다.
  - 규칙의 GUI 확인 화면입니다(Windows Defender Firewall with Advanced Security → Outbound Rules → 규칙 더블클릭). 왼쪽은 Programs and Services 탭(대상 프로그램), 오른쪽은 Protocols and Ports 탭(TCP, 원격 포트 80·443)입니다(조회, 2026-11-04).

    [![LAB-CloudSync-AgentUpdater 규칙 속성(GUI)]({{ "/assets/images/2026/11/cs-fw-gui-02-rule-properties.png" | relative_url }})]({{ "/assets/images/2026/11/cs-fw-gui-02-rule-properties.png" | relative_url }}){:target="_blank"}

  - 이 규칙(`LAB-CloudSync-AgentUpdater-TCP80-443`)은 PowerShell로 만들었습니다(조회: 입력 이력). 같은 입력에서 업데이트 서비스를 다시 시작하고 설치 폴더를 열어 봤습니다.

    ```powershell
    New-NetFirewallRule -DisplayName 'LAB-CloudSync-AgentUpdater-TCP80-443' -Direction Outbound `
      -Program 'C:\Program Files\Microsoft Azure AD HIS Agent\AzureADConnectAgentUpdater.exe' `
      -Protocol TCP -RemotePort 80,443 -Action Allow
    Restart-Service AzureADConnectAgentUpdater
    ```
- 다음 글: 서버 쪽 Connect Health 에이전트 설치가 실패하고 되돌린 경위(별도 글)와, 두 동기화 방식으로 클라이언트를 하이브리드 조인하는 과정.

## 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (10건)</summary>

- (조회) 서비스·설치 버전·방화벽 규칙: sync01 PowerShell (2026-11-04)
- (조회) 차단 이벤트 집계: sync01 보안 로그 5157 (2026-11-04)
- (조회) 마법사 화면: 2026-11-03 08:16 ~ 08:53 사용자 캡처 원본
- (조회) NRPT·이름 풀이 결과: 2026-11-03 08:25 캡처, 현재 규칙·입력 이력은 2026-11-04 조회
- (조회) ESC 허용 사이트 레지스트리 값과 키 쓰기 시각, 신뢰할 수 있는 사이트 화면: sync01 (2026-11-04)
- (조회) 에이전트 마법사 로그: `Trace\trace-wizard-20261103-083407.log` (2026-11-04)
- (조회) Application 이벤트 로그: 출처 Azure AD Connect Provisioning Agent의 08:40:09·08:42:42 오류 이벤트 (2026-11-04)
- (문서) [Cloud Sync 필수 요건(방화벽·프록시, gMSA)](https://learn.microsoft.com/entra/identity/hybrid/cloud-sync/how-to-prerequisites)
- (문서) [Cloud Sync 문제 해결(에이전트 확인, 포트)](https://learn.microsoft.com/entra/identity/hybrid/cloud-sync/how-to-troubleshoot)
- (문서) [Connect Health 에이전트 설치 요건(IE 보안 강화 구성 허용 사이트)](https://learn.microsoft.com/entra/identity/hybrid/connect/how-to-connect-health-agent-install)

</details>
