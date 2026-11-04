---
title: "[IAM] 온프레미스 AD 도메인 구성하고 상태 점검하기"
date: 2026-11-02 21:30:00 +0900
categories: [iam]
phase: 하이브리드 실습
seq: 2
tags: [IAM, Active Directory, 도메인 컨트롤러, DNS, OU 설계, dcdiag]
excerpt: "Windows Server 2022 한 대를 새 포리스트의 도메인 컨트롤러로 올리고, 동기화 범위를 나누려고 OU를 설계했다. dcdiag는 관리자 권한 셸에서 돌려야 정확하다"
toc: true
---

하이브리드 ID 실습의 출발점인 온프레미스 AD를 `sionnote.local` 도메인 컨트롤러 한 대로 구성했습니다. 이 글은 만든 결과(역할·OU·DNS)와 `dcdiag`로 확인한 상태를 정리합니다. 도메인 승격 마법사를 진행하던 시점의 캡처는 남아 있지 않아서, 절차는 Microsoft Learn 기준으로 적고 결과는 지금 서버에서 직접 읽은 값으로 채웠습니다.

## 요약

- 새 포리스트 하나, DC 한 대(ad01)이고 FSMO 5개 역할이 모두 ad01에 있음
- OU는 `CloudSyncLab` 아래 `ConnectSync`·`CloudSync`로 나눠, 두 동기화 방식이 서로 다른 클라이언트를 맡게 함
- `dcdiag`는 일반 권한 셸에서 접근 거부로 4개가 실패했고, 관리자 권한에서는 SystemLog 1건만 남음

> 근거 표기: 조회 = 이 랩에서 직접 읽은 값 · 문서 = Microsoft Learn · 확인 불가 = 시도했지만 확인하지 못한 값(방법·사유 병기). 테넌트 ID·도메인·계정 등 비공개 정보는 가리거나 게시하지 않았습니다.

---

## 전체 기록

### 1. 목표

동기화 서버(Connect Sync, Cloud Sync)와 클라이언트(Windows 10·11)를 붙일 수 있는 최소한의 AD를 만듭니다. DC를 여러 대 두면 점검할 것이 늘어나므로 한 대로 시작했습니다.

### 2. 개념

| 용어 | 뜻 | 이 랩에서의 값(조회) |
|---|---|---|
| 포리스트·도메인 | AD의 최상위 경계와 그 안의 도메인 | 포리스트 1개, 도메인 `sionnote.local`(NetBIOS `SIONNOTE`) |
| 기능 수준 | 사용할 수 있는 AD 기능의 하한선 | 도메인·포리스트 모두 Windows Server 2016 |
| FSMO 역할 | 한 곳에서만 처리해야 하는 작업 5종(스키마·도메인 명명·RID·PDC·인프라) | 5개 모두 `sionnote-ad01.sionnote.local` |
| OU | 계정을 묶고 범위를 나누는 폴더 | 아래 3절 표 |

### 3. 결과

#### 3-1. 도메인 컨트롤러

| 항목 | 값(조회) | 읽은 방법 |
|---|---|---|
| 서버 | SIONNOTE-AD01, Windows Server 2022 Standard Evaluation | `Get-ADDomainController` |
| 설치된 역할 | AD DS, DNS 서버, RSAT-AD-PowerShell | `Get-WindowsFeature` |
| 글로벌 카탈로그 | 예 | `Get-ADDomainController` |
| 스키마 버전 | 88 | `objectVersion` 속성 |
| 공유 폴더 | SYSVOL, NETLOGON | `Get-SmbShare` |
| AD 휴지통 | 사용 안 함(EnabledScopes 비어 있음) | `Get-ADOptionalFeature` |
| 도메인 암호 정책 | 최소 7자, 복잡성 사용, 최대 사용 기간 42일, 잠금 임계값 0 | `Get-ADDefaultDomainPasswordPolicy` |

**FSMO 역할 GUI 확인**: Active Directory 사용자 및 컴퓨터에서 `sionnote.local`을 우클릭 → **Operations Masters…**를 열면 RID, PDC, Infrastructure 탭에서 각 역할을 가진 서버를 볼 수 있습니다(조회, 2026-11-04). 세 탭 모두 `sionnote-ad01.sionnote.local`입니다. 스키마 마스터는 Active Directory 스키마 스냅인에서, 도메인 명명 마스터는 Active Directory 도메인 및 트러스트에서 확인하는 항목이라 이 화면에는 없습니다. 이 둘과 나머지는 아래 PowerShell(`Get-ADForest`, `Get-ADDomain`)로 읽었습니다.

![Operations Masters: RID·PDC·Infrastructure 탭(GUI)]({{ "/assets/images/2026/11/ad-gui-04-operations-masters.png" | relative_url }})

<details markdown="1">
<summary>원본 캡처 보기 (터미널 화면, 해상도 낮음)</summary>

![ad01에서 읽은 역할·FSMO·스키마·공유·암호 정책]({{ "/assets/images/2026/11/ad-01-dc-facts.png" | relative_url }})

같은 명령과 출력은 글 끝 부록에 텍스트로 있습니다.

</details>

#### 3-2. OU와 컴퓨터 배치

| OU | 들어 있는 것(조회) | 역할 |
|---|---|---|
| Domain Controllers | SIONNOTE-AD01 | 기본 OU |
| Admins | 사용자 1명 | 관리용 계정(동기화 대상 OU로 지정하지 않음) |
| CloudSyncLab > ConnectSync | SIONNOTE-CL10, 사용자 3명, 보안 그룹 `CloudSync-TestGroup` 1개(11-02 21:47 생성) | Connect Sync가 맡는 범위 |
| CloudSyncLab > CloudSync | SIONNOTE-CL11, 사용자 2명 | Cloud Sync가 맡는 범위 |
| CloudSyncLab > Users | 비어 있음 | 예비 |
| CloudSyncLab > Groups | 전역 보안 그룹 `CloudSync-Group01` 1개(구성원 0, 11-03 08:15 생성) | 예비. Cloud Sync 범위는 OU 기준이라 이 그룹은 범위에 쓰이지 않음(조회: 포털 범위 `OU=CloudSync`) |
| CN=Computers(기본 컨테이너) | SIONNOTE-SYNC01 | 서버 가입 시 기본 위치 |
| CN=Users(기본 컨테이너) | 사용자 4명 | 기본 위치 |

**GUI 확인 경로**: ad01에서 시작 → Windows 관리 도구 → **Active Directory 사용자 및 컴퓨터**(`dsa.msc`) → `sionnote.local` → `CloudSyncLab` 아래 OU를 하나씩 선택합니다(조회, 2026-11-04). 오른쪽 목록에 각 OU의 컴퓨터·사용자·그룹이 보입니다.

![ConnectSync OU: 보안 그룹 1개, 컴퓨터 SIONNOTE-CL10, 사용자 3명(GUI)]({{ "/assets/images/2026/11/ad-gui-01-aduc-connectsync.png" | relative_url }})

![CloudSync OU: 컴퓨터 SIONNOTE-CL11, 사용자 2명(GUI)]({{ "/assets/images/2026/11/ad-gui-02-aduc-cloudsync.png" | relative_url }})

![Computers 기본 컨테이너: SIONNOTE-SYNC01(GUI)]({{ "/assets/images/2026/11/ad-gui-03-aduc-computers.png" | relative_url }})

Groups OU에는 전역 보안 그룹 `CloudSync-Group01`이 있고 구성원은 없습니다(조회). Users OU는 비어 있습니다. 아래 PowerShell 화면은 같은 내용을 명령으로 읽은 것입니다.

<details markdown="1">
<summary>원본 캡처 보기 (터미널 화면, 해상도 낮음)</summary>

![ad01에서 읽은 OU 구조와 컴퓨터 배치]({{ "/assets/images/2026/11/ad-02-ou-computers.png" | relative_url }})

같은 명령과 출력은 글 끝 부록에 텍스트로 있습니다.

</details>

#### 3-3. DNS

| 항목 | 값(조회) |
|---|---|
| 정방향 영역 | `sionnote.local`, `_msdcs.sionnote.local` (둘 다 AD 통합) |
| 역방향 영역 | 기본 3개(0·127·255.in-addr.arpa, AD 통합 아님) |
| 포워더 | 없음(`Get-DnsServerForwarder` 출력 없음) |

ad01에는 인터넷으로 나가는 NIC가 없어서, 포워더가 없어도 도메인 안의 이름 풀이에는 문제가 없습니다. sync01은 인터넷 이름을 찾을 때 NAT 스위치 쪽 NIC의 DNS를 씁니다(앞 글 3-3 표 참고).

#### 3-4. dcdiag 결과

| 실행 방식 | 실패한 테스트 | 원인 |
|---|---|---|
| 일반 권한 PowerShell | NetLogons, Replications, Services, SystemLog | 앞의 세 개는 "접근 거부"(오류 0x5, 0x2105) — 권한 문제 |
| **관리자 권한 PowerShell** | SystemLog 1건 | 최근 System 로그의 오류 이벤트 1건(아래 6절) |

나머지(Connectivity, Advertising, SysVolCheck, KccEvent, KnowsOfRoleHolders, MachineAccount, NCSecDesc, ObjectsReplicated, RidManager, VerifyReferences, 포리스트·도메인 DNS 영역, 스키마·구성 CrossRefValidation, LocatorCheck, Intersite)는 모두 passed였습니다.

<details markdown="1">
<summary>원본 캡처 보기 (터미널 화면, 해상도 낮음)</summary>

![관리자 권한 dcdiag 결과]({{ "/assets/images/2026/11/ad-03-dcdiag.png" | relative_url }})

같은 명령과 출력은 글 끝 부록에 텍스트로 있습니다.

</details>

### 4. 운영 판단

- OU를 동기화 방식별로 나눈 것이 이 시리즈의 핵심 설계입니다. "어느 OU에 있는 계정·컴퓨터를 어느 동기화가 올리는가"를 OU 하나로 설명할 수 있어서, 하이브리드 조인 결과를 비교하기 쉬워집니다.
- `Admins` OU는 두 동기화 범위(ConnectSync·CloudSync OU) 밖에 있습니다. 이 OU의 계정은 Entra에 올라가지 않으므로, 하이브리드 조인한 PC에 이 계정으로 로그인하면 PRT가 나오지 않을 것으로 보입니다(추정, 뒤 글에서 사례를 다룸).
- AD 휴지통을 쓰지 않으므로 계정을 삭제하면 되돌릴 수 없습니다. 실습 중 삭제는 하지 않는 것을 기본으로 했습니다.

### 5. 절차

승격 마법사 캡처는 없어서 문서 기준의 흐름만 적습니다(확인 불가: 방법 = 사용자 스크린샷 폴더 검색, 사유 = 승격 시점의 캡처가 폴더에 없음).

1. 서버 관리자 → 역할 및 기능 추가에서 **Active Directory 도메인 서비스**를 설치합니다(문서).
2. 결과 화면의 **이 서버를 도메인 컨트롤러로 승격**을 눌러 마법사를 엽니다(문서).
3. 배포 구성에서 **새 포리스트 추가**를 고르고 루트 도메인 이름을 입력합니다. 단일 레이블 이름은 쓸 수 없습니다(문서). DNS 서버·글로벌 카탈로그를 유지하고 DSRM 암호를 정합니다(문서).
4. 서버가 재시작되면 도메인 계정으로 로그인합니다. 이 랩에서 ad01의 컴퓨터 계정 암호가 마지막으로 설정된 시각이 2026-11-02 21:10이라, 승격은 그 무렵으로 보입니다(추정).

이후 OU와 사용자는 Active Directory 사용자 및 컴퓨터(ADUC)에서 만들었습니다.

### 6. 막힌 곳

- **일반 권한 셸에서 dcdiag가 4개 실패**: `whoami /groups`에 High Mandatory Level이 없는 상태(관리자 권한 아님)로 돌렸을 때 NetLogons·Replications·Services가 "접근 거부"로 실패했습니다. 문서도 dcdiag를 관리자 권한(elevated) 셸에서 실행하라고 안내합니다(문서). 관리자 권한으로 다시 열어 같은 명령을 실행하자 세 항목이 passed로 바뀌었습니다.
- **SystemLog 실패의 원인**: 이 테스트는 최근 60분 사이 System 로그의 오류·경고를 읽습니다(문서). 로그에는 SIONNOTE-CL11의 세션 설정이 "보안 데이터베이스에 신뢰 계정 SIONNOTE-CL11$ 없음"으로 실패한 이벤트(ID 0x165B)가 있었습니다. 이어서 컴퓨터 계정을 조회해 보니 CL11이 **비활성(Enabled=False)** 이었습니다.
- **비활성의 이유(추정)**: cl11은 Entra 조인을 시험할 때 작업 그룹으로 바꿔 도메인을 떠났습니다. 그 뒤 하이브리드 조인 상태의 체크포인트로 되돌렸는데, 되돌린 것은 PC의 디스크일 뿐 AD에 남은 컴퓨터 계정은 그대로라서 계정만 비활성 상태로 남은 것으로 보입니다. 비활성이 된 정확한 시점과 이벤트는 확인하지 않았습니다(확인 불가: 방법 = DC 보안 로그 4725 이벤트 미조회, 사유 = 이번 글 범위 밖). 참고로 같은 방식으로 Entra 조인을 시험한 cl10은 컴퓨터 계정이 활성이어서, cl10도 도메인을 떠났는지는 확인하지 못했습니다.
- **조치와 결과**: 계정을 다시 활성화했습니다(`Enable-ADAccount`). 이후 cl11에서 `nltest /sc_query:sionnote.local`을 실행하자 트러스트된 DC가 ad01로 나오고 연결 상태가 `NERR_Success`였으며, `dsregcmd /status`는 AzureAdJoined·DomainJoined가 모두 YES, DeviceAuthStatus는 SUCCESS였습니다(조회). cl10도 같은 값(AzureAdJoined·DomainJoined YES)이었습니다. 두 PC 모두 하이브리드 조인 상태로 정상입니다.

### 7. 정리·남은 일

- 체크포인트를 적용한 클라이언트는 AD 계정 상태(Enabled, 암호 설정 시각)가 PC와 어긋날 수 있으니, 적용한 뒤 `Get-ADComputer`로 확인하는 것이 안전합니다.
- 다음 글: 동기화 서버(sync01)를 도메인에 가입시키는 과정.

<details markdown="1">
<summary>확인 불가 항목 (2건)</summary>

- 승격 마법사 화면과 입력값: 당시 캡처가 폴더에 없음. 문서 기준 흐름만 기재.
- CL11 계정이 비활성이 된 정확한 시점과 원인 이벤트: DC 보안 로그(4725) 미조회.

</details>

### 부록. 사용한 명령과 출력

ad01의 PowerShell에서 실행한 명령과 결과입니다(2026-11-04). 화면 캡처는 위 그림에 있고, 같은 내용을 복사할 수 있는 텍스트로 옮겼습니다.

**도메인·DC·OU**

```powershell
$d=Get-ADDomain; $f=Get-ADForest
"Domain: $($d.DNSRoot) / NetBIOS: $($d.NetBIOSName) / DomainMode: $($d.DomainMode) / ForestMode: $($f.ForestMode)"
Get-ADDomainController -Filter * | Select Name,IPv4Address,OperatingSystem,IsGlobalCatalog | ft -AutoSize
Get-ADOrganizationalUnit -Filter * | Select Name,DistinguishedName | ft -AutoSize -Wrap
```

```text
Domain: sionnote.local / NetBIOS: SIONNOTE / DomainMode: Windows2016Domain / ForestMode: Windows2016Forest

Name          IPv4Address OperatingSystem                           IsGlobalCatalog
----          ----------- ---------------                           ---------------
SIONNOTE-AD01 10.10.10.10 Windows Server 2022 Standard Evaluation              True

Name               DistinguishedName
----               -----------------
Domain Controllers OU=Domain Controllers,DC=sionnote,DC=local
CloudSyncLab       OU=CloudSyncLab,DC=sionnote,DC=local
Users              OU=Users,OU=CloudSyncLab,DC=sionnote,DC=local
Groups             OU=Groups,OU=CloudSyncLab,DC=sionnote,DC=local
ConnectSync        OU=ConnectSync,OU=CloudSyncLab,DC=sionnote,DC=local
CloudSync          OU=CloudSync,OU=CloudSyncLab,DC=sionnote,DC=local
Admins             OU=Admins,DC=sionnote,DC=local
```

**컴퓨터 계정, OU별 사용자 수, DNS 영역**

```powershell
Get-ADComputer -Filter * | Select Name,DistinguishedName | ft -AutoSize -Wrap
Get-ADUser -Filter * -Properties Enabled | Group-Object {($_.DistinguishedName -split ',',2)[1]} | Select Count,Name | ft -AutoSize -Wrap
(Get-ADForest).UPNSuffixes
Get-DnsServerZone | Select ZoneName,ZoneType,IsDsIntegrated | ft -AutoSize
Get-DnsServerForwarder | Select -Expand IPAddress
```

```text
Name           DistinguishedName
----           -----------------
SIONNOTE-AD01  CN=SIONNOTE-AD01,OU=Domain Controllers,DC=sionnote,DC=local
SIONNOTE-SYNC01 CN=SIONNOTE-SYNC01,CN=Computers,DC=sionnote,DC=local
SIONNOTE-CL10  CN=SIONNOTE-CL10,OU=ConnectSync,OU=CloudSyncLab,DC=sionnote,DC=local
SIONNOTE-CL11  CN=SIONNOTE-CL11,OU=CloudSync,OU=CloudSyncLab,DC=sionnote,DC=local

Count Name
----- ----
    4 CN=Users,DC=sionnote,DC=local
    3 OU=ConnectSync,OU=CloudSyncLab,DC=sionnote,DC=local
    1 OU=Admins,DC=sionnote,DC=local
    2 OU=CloudSync,OU=CloudSyncLab,DC=sionnote,DC=local

<테넌트 기본 도메인>   (UPN 접미사 1개, 값은 가림)

ZoneName              ZoneType IsDsIntegrated
--------              -------- --------------
_msdcs.sionnote.local Primary            True
0.in-addr.arpa        Primary           False
127.in-addr.arpa      Primary           False
255.in-addr.arpa      Primary           False
sionnote.local        Primary            True
```

(`Get-DnsServerForwarder`는 출력이 없었습니다.)

**역할·FSMO·스키마·공유·휴지통·암호 정책**

```powershell
Get-WindowsFeature AD-Domain-Services,DNS,RSAT-AD-PowerShell | Select Name,InstallState | ft -AutoSize
$d=Get-ADDomain;$f=Get-ADForest; "PDC=$($d.PDCEmulator) RID=$($d.RIDMaster) Infra=$($d.InfrastructureMaster) Schema=$($f.SchemaMaster) Naming=$($f.DomainNamingMaster)"
"SchemaVersion=" + (Get-ADObject (Get-ADRootDSE).schemaNamingContext -Properties objectVersion).objectVersion
Get-SmbShare | ? Name -match 'SYSVOL|NETLOGON' | Select Name,Path | ft -AutoSize
Get-ADOptionalFeature 'Recycle Bin Feature' | Select Name,EnabledScopes | fl
Get-ADDefaultDomainPasswordPolicy | Select MinPasswordLength,ComplexityEnabled,MaxPasswordAge,LockoutThreshold | ft -AutoSize
```

```text
Name                InstallState
----                ------------
AD-Domain-Services     Installed
DNS                    Installed
RSAT-AD-PowerShell     Installed

PDC=sionnote-ad01.sionnote.local RID=sionnote-ad01.sionnote.local Infra=sionnote-ad01.sionnote.local Schema=sionnote-ad01.sionnote.local Naming=sionnote-ad01.sionnote.local
SchemaVersion=88

Name     Path
----     ----
NETLOGON C:\Windows\SYSVOL\sysvol\sionnote.local\SCRIPTS
SYSVOL   C:\Windows\SYSVOL\sysvol

Name          : Recycle Bin Feature
EnabledScopes : {}

MinPasswordLength ComplexityEnabled MaxPasswordAge LockoutThreshold
----------------- ----------------- -------------- ----------------
                7              True 42.00:00:00                  0
```

**dcdiag(관리자 권한 PowerShell에서 실행)**

```powershell
whoami /groups | Select-String 'High Mandatory'      # 관리자 권한 여부 (일반 권한 셸은 결과 없음)
dcdiag | Select-String 'passed test|failed test' | % { $_.Line.Trim(' .') }
dcdiag /test:SystemLog | Select-String 'An (Error|Warning) Event|Event ID|Event String|Time Generated|passed|failed' | % { $_.Line.Trim() } | Select -First 30
```

SystemLog 실패 항목의 상세(발췌):

```text
An error event occurred.  EventID: 0x0000165B
Time Generated: 11/04/2026   10:46:30
Event String:
The session setup from computer 'SIONNOTE-CL11' failed because the security database does not contain a trust account 'SIONNOTE-CL11$' referenced by the specified ...
SIONNOTE-AD01 failed test SystemLog
```

**컴퓨터 계정 상태 확인과 조치**

```powershell
Get-ADComputer -Filter * -Properties Enabled,PasswordLastSet,LastLogonDate,userCertificate |
  Select Name,Enabled,PasswordLastSet,LastLogonDate,@{n='Cert';e={$_.userCertificate.Count}} | ft -AutoSize
Get-WinEvent -FilterHashtable @{LogName='System';Id=5805,5723,5722,5721;StartTime=(Get-Date).AddHours(-3)} -ErrorAction SilentlyContinue |
  Group-Object Id,@{e={($_.Message -split "'")[1]}} | Select Count,Name | ft -AutoSize
Enable-ADAccount -Identity 'SIONNOTE-CL11$'
Get-ADComputer SIONNOTE-CL11 | Select Name,Enabled | ft -AutoSize
```

```text
Name            Enabled PasswordLastSet       LastLogonDate         Cert
----            ------- ---------------       -------------         ----
SIONNOTE-AD01      True 11/2/2026 9:10:47 PM  11/2/2026 9:10:59 PM     0
SIONNOTE-SYNC01    True 11/2/2026 10:51:05 PM 11/2/2026 10:51:05 PM    0
SIONNOTE-CL10      True 11/3/2026 3:28:25 PM  11/3/2026 3:28:25 PM     1
SIONNOTE-CL11     False 11/3/2026 4:01:44 PM  11/3/2026 4:02:08 PM     1

Count Name
----- ----
    1 5723, SIONNOTE-CL11

Name          Enabled
----          -------
SIONNOTE-CL11    True
```

cl11 쪽에서 보안 채널을 확인한 명령은 [도메인 가입 글]({{ "/iam/ad-domain-join/" | relative_url }})의 부록에 있습니다.

## 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (7건)</summary>

- (조회) 도메인·DC·OU·컴퓨터·DNS·FSMO·스키마·공유·암호 정책: ad01 관리자 PowerShell (2026-11-04)
- (조회) dcdiag 전체 결과와 SystemLog 상세: ad01 관리자 권한 PowerShell (`dcdiag`, `dcdiag /test:SystemLog`)
- (조회) 컴퓨터 계정 상태: `Get-ADComputer -Filter * -Properties Enabled,PasswordLastSet,LastLogonDate`
- (문서) [AD DS 설치와 도메인 컨트롤러 승격](https://learn.microsoft.com/windows-server/identity/ad-ds/deploy/install-active-directory-domain-services--level-100-)
- (문서) [AD DS 구성 마법사 페이지 설명(새 포리스트)](https://learn.microsoft.com/windows-server/identity/ad-ds/deploy/ad-ds-installation-and-removal-wizard-page-descriptions)
- (문서) [DCDiag 명령(관리자 권한 실행, 테스트 설명)](https://learn.microsoft.com/windows-server/administration/windows-commands/dcdiag)
- (문서) [AD 복제 오류 5(접근 거부) 문제 해결](https://learn.microsoft.com/troubleshoot/windows-server/active-directory/replications-fail-with-error-5)

</details>
