---
title: "[IAM] Connect Sync 설치하고 방화벽 규칙 하나씩 열기"
date: 2026-11-03 01:10:00 +0900
last_modified_at: 2026-11-04 22:00:00 +0900
categories: [iam]
phase: 하이브리드 실습
seq: 4
tags: [IAM, Entra Connect Sync, 방화벽, 아웃바운드 차단, OU 필터링, 암호 해시 동기화]
excerpt: "아웃바운드를 기본 차단한 sync01에 Connect Sync를 설치했다. 마법사가 막힐 때마다 막힌 프로그램에만 TCP 80·443 규칙을 열었고, OU 필터는 ConnectSync 하나만 골랐다"
toc: true
---

회사 환경처럼 "밖으로 나가는 통신은 기본 차단, 필요한 프로그램만 허용"하는 서버에 Entra Connect Sync를 설치했습니다. 설치 마법사가 오류로 멈출 때마다 어떤 프로그램이 막혔는지 찾아 그 프로그램만 열었고, 마지막에 설치가 끝났습니다. 이 글은 설치 화면과 열어 준 규칙을 순서대로 정리합니다.

## 요약

- 마법사(`AzureADConnect.exe`)와 동기화 엔진(`miiserver.exe`)은 각각 따로 규칙이 있어야 통과함
- SocketException은 miiserver.exe의 443 차단 기록(10건)으로 확인했고, HttpRequestException·0x80072efd는 규칙을 만든 뒤 통과한 점으로 방화벽 차단이라고 판단했으며(추정: 집계 결과에 AzureADConnect.exe 줄이 없음), NoNetwork(DC에 인터넷 경로 없음)와 이름 풀이 실패(0x80072ee7)는 별개 원인이거나 방화벽과 DNS를 구분하지 못했음
- OU 필터는 `CloudSyncLab > ConnectSync` 하나만 선택해 클라이언트·사용자 범위를 좁힘

> 근거 표기: 조회 = 이 랩에서 직접 읽은 값 · 문서 = Microsoft Learn · 확인 불가 = 시도했지만 확인하지 못한 값(방법·사유 병기). 테넌트 ID·테넌트 도메인·클라우드 계정(UPN)은 가렸고, 개인 실습용 도메인(sionnote.local)의 계정 이름·장치 이름·호스트 이름은 그대로 보일 수 있습니다.

---

## 전체 기록

### 1. 목표

sync01(도메인 가입 서버)에 Connect Sync를 설치하고, `OU=ConnectSync` 아래의 사용자만 Entra ID로 동기화합니다. 방화벽은 기본 차단 상태를 유지하고 필요한 구멍만 뚫습니다.

### 2. 개념

| 구성 | 설명 | 이 랩의 값(조회) |
|---|---|---|
| 설치 마법사 | 설치·구성을 하는 프로그램. 구성 중 Entra ID에 로그인해 테넌트를 확인함 | `AzureADConnect.exe` |
| 동기화 엔진 | 설치 후 실제로 AD와 Entra ID 사이를 동기화하는 서비스(ADSync) | `miiserver.exe`, 서비스 계정 `NT SERVICE\ADSync` |
| 설치된 버전 | 제어판 프로그램 목록 | Microsoft Entra Connect Sync 2.6.92.0 |
| 로그인 방식 | 사용자가 클라우드에서 인증하는 방법 | 암호 해시 동기화(Ready to configure 화면에 표시) |

방화벽이 "기본 차단"이면 프로그램마다 허용 규칙이 있어야 합니다. 문서는 Connect 서버가 Entra ID로 TCP 443(동기화)과 80(인증서 폐기 목록)을 쓴다고 안내합니다(문서).

### 3. 결과

#### 3-1. 시작 상태

sync01의 방화벽은 세 프로필(도메인·개인·공용) 모두 **켜짐, 인바운드 차단(기본), 아웃바운드 차단**입니다.

[![sync01 방화벽 도메인 프로필: 아웃바운드 연결 Block]({{ "/assets/images/2026/11/cs-fw-01-profile-block.png" | relative_url }})]({{ "/assets/images/2026/11/cs-fw-01-profile-block.png" | relative_url }}){:target="_blank"}

#### 3-2. 마법사 설정값

| 마법사 페이지 | 선택한 값 | 비고 |
|---|---|---|
| Express Settings | **Customize** | 화면에 "sionnote.local은 라우팅되지 않는 도메인"이라는 경고가 있어 사용자 지정을 권장함 |
| User Sign-In | 암호 해시 동기화 | 기본값 |
| Connect to Microsoft Entra ID | 하이브리드 ID 관리자 권한의 클라우드 계정 | 계정 정보는 가림 |
| Connect your directories | 포리스트 `sionnote.local`, **Create new AD account**(Enterprise Admin 자격으로 생성) | |
| Microsoft Entra sign-in | UPN 특성 `userPrincipalName`, "Continue without matching all UPN suffixes to verified domains" **해제** | 아래 4절 |
| Domain/OU Filtering | **Sync selected domains and OUs** → `ConnectSync`만 체크 | |
| Uniquely identifying your users | 기본값(Entra가 소스 앵커 관리) | 완료 화면에 `mS-DS-ConsistencyGuid`로 표시 |
| Optional Features | 기본값 | Ready 화면에 암호 해시 동기화와 삭제 임계값 500이 표시됨 |

[![Connect to Microsoft Entra ID 페이지]({{ "/assets/images/2026/11/cs-02-entra-signin.png" | relative_url }})]({{ "/assets/images/2026/11/cs-02-entra-signin.png" | relative_url }}){:target="_blank"}

[![Connect your directories: 디렉터리 추가됨]({{ "/assets/images/2026/11/cs-03-directories.png" | relative_url }})]({{ "/assets/images/2026/11/cs-03-directories.png" | relative_url }}){:target="_blank"}

[![AD forest account: 새 AD 계정 만들기]({{ "/assets/images/2026/11/cs-04-ad-forest-account.png" | relative_url }})]({{ "/assets/images/2026/11/cs-04-ad-forest-account.png" | relative_url }}){:target="_blank"}

[![Microsoft Entra sign-in configuration: UPN 접미사 표]({{ "/assets/images/2026/11/cs-05-signin-config.png" | relative_url }})]({{ "/assets/images/2026/11/cs-05-signin-config.png" | relative_url }}){:target="_blank"}

[![Domain and OU filtering: ConnectSync만 선택]({{ "/assets/images/2026/11/cs-06-ou-filter.png" | relative_url }})]({{ "/assets/images/2026/11/cs-06-ou-filter.png" | relative_url }}){:target="_blank"}

[![Ready to configure]({{ "/assets/images/2026/11/cs-07-ready.png" | relative_url }})]({{ "/assets/images/2026/11/cs-07-ready.png" | relative_url }}){:target="_blank"}

[![Configuration complete]({{ "/assets/images/2026/11/cs-08-complete.png" | relative_url }})]({{ "/assets/images/2026/11/cs-08-complete.png" | relative_url }}){:target="_blank"}

설치 중간 단계 세 화면도 남아 있습니다(11-03 00:23~00:24). 위 표의 값과 같은 내용을 화면으로 확인합니다.

[![Uniquely identifying your users: 기본값(소스 앵커는 Azure가 관리)]({{ "/assets/images/2026/11/cs-09-identifying-users.png" | relative_url }})]({{ "/assets/images/2026/11/cs-09-identifying-users.png" | relative_url }}){:target="_blank"}

[![Filter users and devices: Synchronize all users and devices]({{ "/assets/images/2026/11/cs-10-filter-users-devices.png" | relative_url }})]({{ "/assets/images/2026/11/cs-10-filter-users-devices.png" | relative_url }}){:target="_blank"}

[![Optional features: 기본값, 툴팁은 Exchange hybrid deployment 설명]({{ "/assets/images/2026/11/cs-11-optional-features.png" | relative_url }})]({{ "/assets/images/2026/11/cs-11-optional-features.png" | relative_url }}){:target="_blank"}

- **Uniquely identifying your users**: "Users are represented on…"으로 시작하는 첫 번째 옵션(기본값)이 선택돼 있고, 소스 앵커는 "Let Azure manage the source anchor"(기본값)입니다. 화면 아래 안내문은 조직이 `mS-DS-ConsistencyGuid`를 쓰고 있지 않으면 Azure가 소스 앵커를 온프레미스 디렉터리에 써 넣는다는 내용입니다.
- **Filter users and devices**: "Synchronize all users and devices"(기본값)입니다. 그룹 기반 시범 배포 필터는 쓰지 않았고, 범위는 앞 단계의 OU 선택(ConnectSync)으로만 정했습니다.
- **Optional features**: 기본값 그대로 두었습니다. 화면의 툴팁은 Exchange hybrid deployment 항목 설명입니다.

완료 화면에는 경고가 세 개 있었습니다. AD 휴지통 미사용, TPM 사용 권장, 그리고 **Connect Health 에이전트 설치 실패**입니다. 마지막 항목은 별도 글에서 다룹니다.

#### 3-3. 열어 준 방화벽 규칙

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/lab-outbound-block-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/lab-outbound-block.png" | relative_url }}" alt="sync01 아웃바운드 차단 구성: 기본 차단과 프로그램별 허용 규칙" loading="lazy"></picture>

| 규칙 이름 | 대상 프로그램 | 포트 | 열게 된 계기 |
|---|---|---|---|
| LAB-Allow-Internal-Out | 모든 프로그램 | 모든 포트 → `LAB_NET` | 도메인 통신(DNS·LDAP·Kerberos 등)을 위해 내부망 전체 허용 |
| LAB-AADConnect-Wizard-TCP80-443 | `AzureADConnect.exe` | TCP 80, 443 | 마법사가 Entra ID 연결 단계에서 HttpRequestException으로 멈춤 |
| LAB-ADSync-Engine-TCP80-443 | `miiserver.exe` | TCP 80, 443 | Configure 단계에서 "Azure Service Connectivity Failed" |

**GUI 확인 경로**: 시작 → Windows Defender Firewall with Advanced Security(`wf.msc`) → 왼쪽 **Outbound Rules**에서 이름이 `LAB-`로 시작하는 규칙을 봅니다. 아래는 사용 여부(Enabled), 동작(Action), 대상 주소(Remote Address), 프로토콜, 원격 포트(Remote Port) 열이 보이게 조정한 화면입니다(조회, 2026-11-04).

[![Outbound Rules의 LAB- 규칙 7개(GUI)]({{ "/assets/images/2026/11/cs-fw-gui-01-outbound-rules.jpg" | relative_url }})]({{ "/assets/images/2026/11/cs-fw-gui-01-outbound-rules.jpg" | relative_url }}){:target="_blank"}

Program 열은 경로가 길어서 `C:\Progr…`로 잘립니다. 규칙 하나를 더블클릭하면 **Programs and Services** 탭에서 프로그램 경로를, **Protocols and Ports** 탭에서 포트를 볼 수 있습니다(예시 화면은 다음 글의 업데이트 도구 규칙). 모든 규칙의 프로그램 경로를 한 번에 보려면 GUI에서는 규칙을 하나씩 열어야 해서, 아래 PowerShell을 보조로 썼습니다.

**사용한 명령 (조회: sync01 PowerShell)** — 규칙 이름이 `LAB-`로 시작하는 것만 읽어 프로그램·포트·대상 주소를 함께 냅니다.

```powershell
Get-NetFirewallRule -DisplayName 'LAB-*' | ForEach-Object {
  $a  = $_ | Get-NetFirewallApplicationFilter
  $p  = $_ | Get-NetFirewallPortFilter
  $ad = $_ | Get-NetFirewallAddressFilter
  [pscustomobject]@{ Name=$_.DisplayName; Dir=$_.Direction; Act=$_.Action; On=$_.Enabled
                     Port=$p.RemotePort; Prog=(Split-Path $a.Program -Leaf)
                     Remote=($ad.RemoteAddress -join ',') }
} | Format-Table -AutoSize
```

위 명령의 결과(대상 주소·포트 포함)는 다음과 같습니다(조회, 2026-11-04). 첫 줄의 대상 주소는 주소 계획의 변수 이름(`LAB_NET`)으로 바꿔 적었습니다(표기용 치환, 나머지는 원본).

```text
Name                              Dir      Act   On   Port      Prog                       Remote
LAB-Allow-Internal-Out            Outbound Allow True Any       Any                        <LAB_NET>/255.255.255.0
LAB-AADConnect-Wizard-TCP80-443   Outbound Allow True {80,443}  AzureADConnect.exe         Any
LAB-ADSync-Engine-TCP80-443       Outbound Allow True {80,443}  miiserver.exe              Any
LAB-CloudSync-* 3개, LAB-ConnectHealth-* 1개 (뒤 글에서 만든 규칙)  — 모두 Outbound / Allow / True / {80,443} / Any
```

화면으로는 규칙 이름과 프로그램만 좁게 다시 뽑아 글자를 키웠습니다(`Get-NetFirewallRule -DisplayName 'LAB-*'`에 `Get-NetFirewallApplicationFilter`를 연결, 프로그램은 파일 이름만 표시).

[![LAB- 방화벽 규칙 7개: 이름·동작·프로그램(2026-11-04 조회, 글꼴 확대, 화면에서는 LAB- 접두사를 뗌)]({{ "/assets/images/2026/11/cs-fw-03-lab-rules-compact.png" | relative_url }})]({{ "/assets/images/2026/11/cs-fw-03-lab-rules-compact.png" | relative_url }}){:target="_blank"}

이 화면에는 뒤 글에서 만든 Cloud Sync·Connect Health 규칙까지 모두 보입니다. 이 글에서 다루는 것은 앞의 세 규칙(`LAB-Allow-Internal-Out`, `LAB-AADConnect-Wizard-…`, `LAB-ADSync-Engine-…`)입니다.

세 규칙은 모두 **사용(Enabled)** 상태이며, 방향 Outbound, 동작 Allow이고 sync01에서 직접 읽었습니다(조회). 두 번째·세 번째 규칙의 "계기"는 규칙 이름과 오류 화면의 발생 순서로 판단한 것입니다.

### 4. 운영 판단

- **마법사와 엔진을 따로 열어야 하는 이유**: 마법사는 설치 중에만 쓰이는 `AzureADConnect.exe`가, 설치 후에는 서비스 계정으로 도는 `miiserver.exe`가 통신합니다. 마법사의 Configure 단계는 엔진의 연결을 시험하므로 마법사 규칙만으로는 통과하지 못했습니다.
- **UPN 접미사**: 표에서 `sionnote.local`은 Entra ID에 없는 도메인("Not Added")입니다. 라우팅되지 않는 UPN 접미사는 Entra에 그대로 올라가지 못하므로, 동기화할 사용자의 UPN 접미사를 테넌트의 기본 도메인으로 맞춰야 합니다(문서: 확인된 도메인과 일치하지 않으면 로그인할 수 없다는 경고가 화면에도 있음). 이 랩에서는 AD 포리스트에 테넌트 도메인을 UPN 접미사로 추가해 두었습니다(조회: 포리스트 UPN 접미사 1개).
- **OU 필터**: 화면에서 `CloudSync`·`Users`·`Groups`·`Admins`·`Computers`·`Domain Controllers` 등은 선택하지 않았습니다. 컴퓨터 계정의 하이브리드 조인 동기화 범위도 이 선택에 따르므로, cl10이 들어 있는 `ConnectSync` OU만 대상이 됩니다.

동기화 대상 사용자의 UPN 접미사는 GUI로 확인합니다. ad01에서 **Active Directory 사용자 및 컴퓨터** → ConnectSync OU의 사용자를 더블클릭 → **Account** 탭의 "User logon name" 오른쪽 드롭다운이 UPN 접미사입니다(조회, 2026-11-02). 아래 화면은 ConnectSync OU의 테스트 사용자이고, 접미사가 `.local`이 아니라 테넌트의 기본 도메인으로 지정돼 있습니다(도메인 값은 가림). 이 값이 `sionnote.local`이면 위 4절 설명처럼 Entra에 그대로 올라가지 못합니다.

[![ADUC 사용자 속성 > Account 탭: UPN 접미사를 테넌트 기본 도메인으로 지정(GUI)]({{ "/assets/images/2026/11/ad-user-account-upn-suffix.png" | relative_url }})]({{ "/assets/images/2026/11/ad-user-account-upn-suffix.png" | relative_url }}){:target="_blank"}

### 5. 절차

1. sync01에서 로컬 관리자로 `AzureADConnect.msi`를 실행합니다(문서).
   - 실행 전에 파일을 우클릭 → **속성** → **Digital Signatures** 탭에서 서명자가 Microsoft Corporation인지 확인할 수 있습니다. 아래는 DC(ad01)에 먼저 설치하려던 때(11-02 22:12)의 같은 파일 속성 화면입니다(조회).

   [![AzureADConnect.msi 속성 > Digital Signatures: 서명자 Microsoft Corporation, sha256]({{ "/assets/images/2026/11/cs-msi-signature.png" | relative_url }})]({{ "/assets/images/2026/11/cs-msi-signature.png" | relative_url }}){:target="_blank"}

2. Welcome에서 약관에 동의하고 **Continue** → Express Settings에서 **Customize**를 선택합니다(문서).
3. Required Components는 기본값으로 **Install**, User Sign-In은 암호 해시 동기화를 선택합니다(문서).
4. **Connect to Microsoft Entra ID**에서 하이브리드 ID 관리자(권장) 또는 전역 관리자 계정으로 로그인합니다(문서). 이 단계에서 막히면 아래 6절을 봅니다.
5. Connect your directories에서 포리스트를 추가하고 AD forest account 창에서 Enterprise Admin 자격으로 새 AD 계정을 만들게 합니다.
6. Microsoft Entra sign-in configuration에서 UPN 특성을 확인하고, Domain and OU filtering에서 **Sync selected domains and OUs → ConnectSync**를 선택합니다(문서).
7. Ready to configure에서 **Install**. 완료 후 Synchronization Service Manager를 쓰려면 한 번 로그아웃했다가 다시 로그인합니다(문서).

### 6. 막힌 곳

#### 6-1. DC(ad01)에 먼저 설치하려다 실패 — NoNetwork

처음에는 도메인 컨트롤러인 ad01에 설치를 시도했고, Connect to Microsoft Entra ID 단계에서 "Unable to validate credentials ... WAM Error ... NoNetwork ... Possible cause: no Internet connection" 오류가 났습니다.

[![ad01에서 Entra ID 로그인 단계 NoNetwork 오류]({{ "/assets/images/2026/11/cs-err-04-dc-nonetwork.png" | relative_url }})]({{ "/assets/images/2026/11/cs-err-04-dc-nonetwork.png" | relative_url }}){:target="_blank"}

ad01은 NIC가 내부 스위치(lab-internal) 하나뿐이라 인터넷으로 나가는 경로가 없습니다(조회: VM 설정). 오류 문구도 인터넷 연결 없음을 원인으로 듭니다. 이 증거를 체크포인트 `evidence-connect-sync-on-DC-blocked`로 남기고, 별도의 멤버 서버 sync01을 새로 만들어 도메인에 가입시킨 뒤 거기에 설치했습니다.

#### 6-2. 마법사: HttpRequestException

sync01에서 같은 단계에 도달하자 이번에는 `HttpRequestException — An error occurred while sending the request`로 마법사가 닫혔습니다. 마법사는 `C:\ProgramData\AADConnect\trace-날짜.log`에 로그를 남긴다고 안내합니다.

[![HttpRequestException 오류]({{ "/assets/images/2026/11/cs-err-01-http.png" | relative_url }})]({{ "/assets/images/2026/11/cs-err-01-http.png" | relative_url }}){:target="_blank"}

`AzureADConnect.exe`용 아웃바운드 규칙을 만들고(TCP 80·443) 마법사를 다시 시작하자 이 단계는 통과했습니다(7절 집계에 `AzureADConnect.exe` 줄이 없어, 차단이 원인이라는 판단은 추정입니다).

#### 6-3. 로그인 창: Something went wrong (두 번)

Microsoft 로그인 창이 "Something went wrong"을 띄운 일이 두 번 있었고, 상세 정보의 오류 코드가 달랐습니다.

| 시각 | 단계 | 오류 코드 | 문서의 의미 |
|---|---|---|---|
| 11-03 00:13(화면 Timestamp, KST) | Connect to Microsoft Entra ID 로그인 | -2147012867 (0x80072efd) | ERROR_INTERNET_CANNOT_CONNECT: 서버 연결 시도 실패(문서: WinINet 오류 목록) |
| 11-03 00:55 | 마법사 마지막의 Health 에이전트 설치 로그인 | -2147012889 (0x80072ee7) | WININET_E_NAME_NOT_RESOLVED: 서버 이름·주소를 확인하지 못함(문서: 하이브리드 조인 문제 해결, WinINet 오류 목록) |

[![로그인 창의 Something went wrong 상세(00:13)]({{ "/assets/images/2026/11/cs-err-03-signin.png" | relative_url }})]({{ "/assets/images/2026/11/cs-err-03-signin.png" | relative_url }}){:target="_blank"}

첫 번째는 연결 자체가 막힌 경우로, 마법사 규칙을 만들고 다시 시작한 뒤 다음 단계(Connect your directories, 00:19)로 넘어갔습니다. 두 번째는 연결이 아니라 **이름 풀이** 실패입니다. 같은 시각 방화벽 차단 집계에 `rundll32.exe`(로그인 창을 띄우는 쪽으로 보임)와 Health 에이전트 서비스의 443 차단이 함께 있었습니다(조회). 그래서 이 구간의 실패는 방화벽 규칙과 DNS 구성이 모두 갖춰지기 전이었던 것으로 보입니다(추정). 두 번째 오류가 방화벽 때문인지 DNS 때문인지는 구분하지 못했고, Health 에이전트 설치는 이후 따로 성공시켰습니다(별도 글).

#### 6-4. Configure 단계: Azure Service Connectivity Failed

Ready to configure에서 Install을 누르자 "The on-premises synchronization service is not able to connect to Microsoft Entra ID"로 멈췄고, 상세에 서비스 계정 `NT SERVICE\ADSync`와 `SocketException: An attempt was made to access a socket in a way forbidden by its access permissions`가 있었습니다. 접속하려던 곳은 Microsoft 로그인 서비스 주소(공개 IP)의 443이었고, 주소는 적지 않았습니다.

[![Configuring: Azure Service Connectivity Failed]({{ "/assets/images/2026/11/cs-err-02-socket.png" | relative_url }})]({{ "/assets/images/2026/11/cs-err-02-socket.png" | relative_url }}){:target="_blank"}

화면은 프록시 설정을 확인하라고 안내하지만, 이 랩은 프록시가 없고 방화벽이 원인이었습니다. 동기화 엔진 `miiserver.exe`에 TCP 80·443 규칙을 열고 다시 실행해 구성이 끝났습니다.

#### 6-5. 어느 프로그램이 막혔는지 찾는 방법

규칙을 하나씩 추측하지 않으려고, 방화벽이 차단한 연결을 프로세스별로 집계해서 봤습니다. 구성 직후 화면입니다. `miiserver.exe`(10건), `azureadconnectagentupdater.exe`(1건), `rundll32.exe`(5건), `microsoft.identity.health.agentv15.service.exe`(20건)가 TCP 443으로 나가다 막힌 기록이었습니다.

<details markdown="1">
<summary>원본 캡처 보기 (터미널 화면, 해상도 낮음)</summary>

[![차단된 연결을 프로그램별로 집계한 결과(구성 직후)]({{ "/assets/images/2026/11/cs-blocked-list.png" | relative_url }})]({{ "/assets/images/2026/11/cs-blocked-list.png" | relative_url }}){:target="_blank"}

같은 집계는 아래 7절의 스크립트와 새 캡처로 다시 확인했습니다.

</details>

이 목록 덕분에 뒤이은 글의 Cloud Sync 에이전트와 Connect Health 에이전트 규칙도 같은 방식으로 열 수 있었습니다. 같은 집계를 오늘(11-04) 다시 돌린 결과와 스크립트는 7절에 있습니다.

#### 6-6. 설치 직후: Synchronization Service Manager가 열리지 않음

설치가 끝난 뒤 Synchronization Service Manager를 열자 "Unable to connect to the Synchronization Service. 1) The service is not started 2) Your account is not a member of a required security group" 대화상자가 떴습니다. 문서는 설치 후 서비스 관리자를 쓰기 전에 로그아웃 후 다시 로그인하라고 안내합니다(문서).

#### 6-7. 설치 파일 실행 때: SmartScreen을 연결할 수 없음

DC(ad01)에서 설치 파일을 실행하자 "SmartScreen can't be reached right now" 창이 먼저 떴습니다(11-02 22:12). 내용은 "인터넷 연결을 확인하라. Microsoft Defender SmartScreen에 연결할 수 없어 이 앱을 실행해도 되는지 판단을 도울 수 없다"입니다. 게시자는 Microsoft Corporation, 앱은 `AzureADConnect.msi`로 표시됩니다. ad01은 NIC가 `lab-internal` 하나뿐이라 인터넷 경로가 없습니다(조회, 앞 글). SmartScreen이 평판 서버에 닿지 못한 것이고, 설치 파일 자체의 문제는 아닙니다. 서명자가 Microsoft Corporation인 것은 위 속성 화면으로 확인했고, 창의 **Run**을 눌러 진행했습니다.

[![SmartScreen can't be reached right now: 게시자 Microsoft Corporation, 앱 AzureADConnect.msi]({{ "/assets/images/2026/11/cs-smartscreen.png" | relative_url }})]({{ "/assets/images/2026/11/cs-smartscreen.png" | relative_url }}){:target="_blank"}

### 7. 차단 이벤트를 프로그램별로 집계하는 방법

GUI만으로는 "어느 프로그램이 막혔는지"를 한눈에 보기 어려워서, 방화벽의 감사 로그를 PowerShell로 집계했습니다. 순서는 세 단계입니다(감사 켜기, 이벤트 보기, 집계).

1. **감사 켜기**: 차단된 연결을 보안 로그(이벤트 5157)에 남기려면 "Filtering Platform Connection" 감사의 실패를 켭니다.

   **GUI 경로**: 시작 → Local Security Policy(`secpol.msc`) → Advanced Audit Policy Configuration → System Audit Policies → **Object Access** → **Audit Filtering Platform Connection**을 더블클릭 → "Configure the following audit events" 체크 후 **Failure**만 체크 → OK. 설정하면 보안 로그에 이벤트 4719(감사 정책 변경)가 남습니다(조회).

   [![Audit Filtering Platform Connection 속성: Failure 체크(GUI)]({{ "/assets/images/2026/11/cs-audit-gui-01-dialog.jpg" | relative_url }})]({{ "/assets/images/2026/11/cs-audit-gui-01-dialog.jpg" | relative_url }}){:target="_blank"}

   [![Object Access 목록에서 Failure로 표시(GUI)]({{ "/assets/images/2026/11/cs-audit-gui-02-list.jpg" | relative_url }})]({{ "/assets/images/2026/11/cs-audit-gui-02-list.jpg" | relative_url }}){:target="_blank"}

   이 랩에서는 처음에 아래 `auditpol` 명령으로 켰습니다(조회: PowerShell 입력 이력). `auditpol`로 켠 값은 시스템에 바로 적용되지만 Local Security Policy 화면에는 "Not configured"로 보입니다(조회, 2026-11-04 화면). 위 GUI 화면은 같은 값(Failure)을 이 화면에서도 설정한 것입니다. Health 글의 4719 조회에는 11-03 14:31:03에 실패 감사가 해제된 기록이 있는데 11-04 12:36~12:51의 5157이 아래 화면에 보이므로, 그 사이 다시 켠 것으로 보입니다(추정: 다시 켠 시각의 4719는 이 글에서 조회하지 않음).

```powershell
auditpol /set /subcategory:"Filtering Platform Connection" /failure:enable
```

2. **이벤트 보기(GUI)**: 시작 → 이벤트 뷰어(`eventvwr.msc`) → Windows 로그 → **Security** → 오른쪽 **Filter Current Log…** → 이벤트 ID에 `5157` 입력 → OK. 이벤트를 하나 선택하면 아래 창에 차단된 프로그램(Application Name), 방향, 대상 포트가 보입니다. 아래 화면은 필터 후 이벤트 11,197건이 나온 상태입니다(조회, 2026-11-04). 주소 값은 가렸습니다.

   [![이벤트 뷰어: 보안 로그를 5157로 필터링(GUI)]({{ "/assets/images/2026/11/cs-eventviewer-5157.png" | relative_url }})]({{ "/assets/images/2026/11/cs-eventviewer-5157.png" | relative_url }}){:target="_blank"}

   이벤트가 많아서 프로그램별 건수·시각은 GUI로 세기 어렵습니다. 그래서 다음 단계는 PowerShell로 집계했습니다.

3. **집계(관리자 권한 PowerShell)**: 이벤트 5157을 읽어 프로그램·대상 포트별 건수와 첫·마지막 발생 시각을 냅니다. 보안 로그를 읽으므로 반드시 관리자 권한 셸이어야 합니다. 일반 권한으로 같은 명령을 돌리면 오류 없이 `blocked events: 0`만 나와서 "차단이 없다"로 오해하기 쉽습니다(조회: 일반 권한 셸에서 0건, 관리자 권한 셸에서 10889건. 감사가 켜져 있어 계속 늘어나, 아래 화면을 찍은 시점에는 11175건).

```powershell
$ev = Get-WinEvent -FilterHashtable @{LogName='Security';Id=5157} -ErrorAction SilentlyContinue
"blocked events: $($ev.Count)"
$ev | ForEach-Object {
    $x = [xml]$_.ToXml(); $d = @{}
    $x.Event.EventData.Data | ForEach-Object { $d[$_.Name] = $_.'#text' }
    [pscustomobject]@{ App=(Split-Path $d.Application -Leaf); Port=$d.DestPort; Time=$_.TimeCreated }
} | Group-Object App,Port |
  Select Count,Name,
    @{n='First';e={($_.Group|Sort Time|Select -First 1).Time.ToString('MM-dd HH:mm')}},
    @{n='Last'; e={($_.Group|Sort Time|Select -Last 1).Time.ToString('MM-dd HH:mm')}} |
  Sort Count -Descending | Format-Table -AutoSize
```

아래 화면은 위 스크립트 끝에 Entra 관련 프로그램만 남기는 필터(`? { $_.Name -match 'miiserver|aadconnect|agentv15|azureadconnect' }`)를 더해 실행한 결과입니다.

[![차단 이벤트 집계 스크립트 실행 결과(2026-11-04, 글꼴 확대)]({{ "/assets/images/2026/11/cs-blocked-script-hires.jpg" | relative_url }})]({{ "/assets/images/2026/11/cs-blocked-script-hires.jpg" | relative_url }}){:target="_blank"}

이 결과에서 이 글과 관련된 줄만 추리면 다음과 같습니다(조회, 날짜는 모두 11-03).

| 프로그램, 포트 | 건수 | 처음 ~ 마지막 | 읽는 법 |
|---|---|---|---|
| `miiserver.exe`, 443 | 10 | 00:25 ~ 00:25 | 구성 단계 오류 시각과 일치하고 이후 차단이 없음 → 이 직후 규칙이 열림 |
| `aadconnectprovisioningagentwizard.exe`, 443 | 8 | 08:27 ~ 08:27 | Cloud Sync 에이전트 마법사(다음 글) |
| `aadconnectprovisioningagent.exe`, 443 | 10 | 08:45 ~ 08:53 | Cloud Sync 에이전트 서비스(다음 글) |
| `microsoft.identity.health.agentv15.service.exe`, 443 | 20 | 00:56 ~ 00:56 | Connect Health 에이전트(별도 글) |
| `azureadconnectagentupdater.exe`, 443 | 4 | 00:29 ~ 11:02 | 에이전트 업데이트 프로그램 |
| `microsoft.identity.health.agentv15.service.exe`, 5671 | 1 | 14:31 ~ 14:31 | Connect Health 에이전트의 서비스 버스 포트(별도 글) |

`svchost.exe`·`System`·`msedgeupdate` 같은 윈도우 자체 프로세스의 차단 기록이 훨씬 많아서(수천 건) 건수만으로 규칙 대상을 고르면 안 됩니다. Microsoft Entra 구성요소와 이름이 맞는 항목만 보고, 그 항목이 언제 처음·마지막으로 막혔는지를 설치 화면의 오류 시각과 맞춰 봤습니다. 이 감사는 보안 로그를 계속 늘리므로 실습이 끝나면 끄는 것이 좋습니다(`/failure:disable`).

### 8. 정리·남은 일

- 설치 완료 시점의 Connect Health 에이전트 설치 실패는 별도 글에서 다룹니다.
- 감사 정책(Filtering Platform Connection)의 실패 감사는 2026-11-04 12:51에도 5157이 기록돼 켜져 있었습니다(조회). 실습을 마무리할 때 끕니다.
- 인터넷 연결 요건은 Microsoft Learn에 포트(80·443)와 URL 목록으로 나와 있습니다. 이 랩은 URL 대신 프로그램 단위로 열어서, 허용된 프로그램은 Any 대상 주소로 나갈 수 있습니다(운영에서는 URL·IP 범위로 더 좁히는 것을 검토).

## 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (9건)</summary>

- (조회) sync01 설치 구성요소·서비스·방화벽 프로필: 관리자 PowerShell (2026-11-04)
- (조회) LAB-* 방화벽 규칙 7개의 프로그램·포트·대상: `Get-NetFirewallRule` + 애플리케이션·포트·주소 필터 (2026-11-04)
- (조회) 마법사 화면·오류: 2026-11-02 23:25 ~ 2026-11-03 01:00 사용자 캡처 원본
- (문서) [Microsoft Entra Connect 필수 요건(방화벽·DNS·프록시)](https://learn.microsoft.com/entra/identity/hybrid/connect/how-to-connect-install-prerequisites)
- (문서) [하이브리드 ID 필수 포트와 프로토콜](https://learn.microsoft.com/entra/identity/hybrid/connect/reference-connect-ports)
- (문서) [Express 설정으로 설치](https://learn.microsoft.com/entra/identity/hybrid/connect/how-to-connect-install-express)
- (문서) [사용자 지정 설치(Domain and OU filtering 포함)](https://learn.microsoft.com/entra/identity/hybrid/connect/how-to-connect-install-custom)
- (문서) [Entra Connect 설치 문제 해결](https://learn.microsoft.com/entra/identity/hybrid/connect/tshoot-connect-install-issues)
- (문서) [WinINet 오류 코드](https://learn.microsoft.com/windows/win32/wininet/wininet-errors) · [하이브리드 조인 문제 해결(WININET_E_NAME_NOT_RESOLVED)](https://learn.microsoft.com/entra/identity/devices/troubleshoot-hybrid-join-windows-current)

</details>
