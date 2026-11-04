---
title: "[IAM] 온프레미스 AD 도메인 구성하고 상태 점검하기"
date: 2026-11-02 21:30:00 +0900
last_modified_at: 2026-11-04 22:00:00 +0900
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
- `dcdiag`는 일반 권한 셸에서 4개가 실패했고(3개는 접근 거부, 1개는 SystemLog), 관리자 권한에서는 SystemLog 1건만 남음

> 근거 표기: 조회 = 이 랩에서 직접 읽은 값 · 문서 = Microsoft Learn · 확인 불가 = 시도했지만 확인하지 못한 값(방법·사유 병기). 테넌트 ID·테넌트 도메인·클라우드 계정(UPN)은 가렸고, 개인 실습용 도메인(sionnote.local)의 계정 이름·장치 이름·호스트 이름은 그대로 보일 수 있습니다.

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

**FSMO 역할 GUI 확인**: Active Directory 사용자 및 컴퓨터에서 `sionnote.local`을 우클릭 → **Operations Masters…**를 열면 RID, PDC, Infrastructure 탭에서 각 역할을 가진 서버를 볼 수 있습니다(조회, 2026-11-04). 아래 화면은 RID 탭이고, PDC·Infrastructure 탭도 같은 `sionnote-ad01.sionnote.local`입니다. 스키마 마스터는 Active Directory 스키마 스냅인에서, 도메인 명명 마스터는 Active Directory 도메인 및 트러스트에서 확인하는 항목이라 이 화면에는 없습니다. 이 둘과 나머지는 아래 PowerShell(`Get-ADForest`, `Get-ADDomain`)로 읽었습니다.

[![Operations Masters: RID 탭, 운영 마스터 sionnote-ad01(GUI)]({{ "/assets/images/2026/11/ad-gui-04-operations-masters.png" | relative_url }})]({{ "/assets/images/2026/11/ad-gui-04-operations-masters.png" | relative_url }}){:target="_blank"}

아래는 ad01의 관리자 PowerShell에서 역할·FSMO·스키마·공유·휴지통·암호 정책을 읽은 화면입니다(2026-11-04, 글꼴 확대). 명령은 글 끝 부록에 있습니다.

[![ad01의 역할·FSMO·스키마·공유·휴지통·암호 정책]({{ "/assets/images/2026/11/ad-hires-03-roles-fsmo-policy.png" | relative_url }})]({{ "/assets/images/2026/11/ad-hires-03-roles-fsmo-policy.png" | relative_url }}){:target="_blank"}

#### 3-2. OU와 컴퓨터 배치

| OU | 들어 있는 것(조회) | 역할 |
|---|---|---|
| Domain Controllers | SIONNOTE-AD01 | 기본 OU |
| Admins | 사용자 1명 | 관리용 계정(동기화 대상 OU로 지정하지 않음) |
| CloudSyncLab > ConnectSync | SIONNOTE-CL10, 사용자 3명, 보안 그룹 `CloudSync-TestGroup` 1개 | Connect Sync가 맡는 범위 |
| CloudSyncLab > CloudSync | SIONNOTE-CL11, 사용자 2명 | Cloud Sync가 맡는 범위 |
| CloudSyncLab > Users | 비어 있음 | 예비 |
| CloudSyncLab > Groups | 전역 보안 그룹 `CloudSync-Group01` 1개(구성원 0) | 예비. Cloud Sync 범위는 OU 기준이라 이 그룹은 범위에 쓰이지 않음(조회: 포털 범위 `OU=CloudSync`) |
| CN=Computers(기본 컨테이너) | SIONNOTE-SYNC01 | 서버 가입 시 기본 위치 |
| CN=Users(기본 컨테이너) | 사용자 4명 | 기본 위치 |

**GUI 확인 경로**: ad01에서 시작 → Windows 관리 도구 → **Active Directory 사용자 및 컴퓨터**(`dsa.msc`) → `sionnote.local` → `CloudSyncLab` 아래 OU를 하나씩 선택합니다(조회, 2026-11-04). 오른쪽 목록에 각 OU의 컴퓨터·사용자·그룹이 보입니다.

[![ConnectSync OU: 보안 그룹 1개, 컴퓨터 SIONNOTE-CL10, 사용자 3명(GUI)]({{ "/assets/images/2026/11/ad-gui-01-aduc-connectsync.png" | relative_url }})]({{ "/assets/images/2026/11/ad-gui-01-aduc-connectsync.png" | relative_url }}){:target="_blank"}

[![CloudSync OU: 컴퓨터 SIONNOTE-CL11, 사용자 2명(GUI)]({{ "/assets/images/2026/11/ad-gui-02-aduc-cloudsync.png" | relative_url }})]({{ "/assets/images/2026/11/ad-gui-02-aduc-cloudsync.png" | relative_url }}){:target="_blank"}

[![Computers 기본 컨테이너: SIONNOTE-SYNC01(GUI)]({{ "/assets/images/2026/11/ad-gui-03-aduc-computers.png" | relative_url }})]({{ "/assets/images/2026/11/ad-gui-03-aduc-computers.png" | relative_url }}){:target="_blank"}

Groups OU에는 전역 보안 그룹 `CloudSync-Group01`이 있고 구성원은 없습니다(조회). Users OU는 비어 있습니다. 아래 두 PowerShell 화면은 같은 내용을 명령으로 읽은 것입니다(글꼴 확대). 첫 화면은 도메인·DC·OU 구조, 둘째 화면은 컴퓨터 계정, OU별 사용자 수, DNS 영역입니다. 명령은 글 끝 부록에 있습니다.

[![도메인·DC·OU 구조(PowerShell)]({{ "/assets/images/2026/11/ad-hires-01-domain-dc-ou.png" | relative_url }})]({{ "/assets/images/2026/11/ad-hires-01-domain-dc-ou.png" | relative_url }}){:target="_blank"}

[![컴퓨터 계정, OU별 사용자 수, DNS 영역(PowerShell)]({{ "/assets/images/2026/11/ad-hires-02-computers-users-dns.png" | relative_url }})]({{ "/assets/images/2026/11/ad-hires-02-computers-users-dns.png" | relative_url }}){:target="_blank"}

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
| 일반 권한 PowerShell | NetLogons, Replications, Services, SystemLog | 앞의 세 개는 "접근 거부"(오류 0x5, 0x2105) — 권한 문제(일반 권한 실행의 출력은 이 글에 없고, 관리자 권한 재실행 결과와의 대비로 적음) |
| **관리자 권한 PowerShell** | SystemLog 1건 | 최근 System 로그의 오류 이벤트 1건(아래 6절) |

나머지(그림에 보이는 항목 전부, 예: Connectivity, Advertising, FrsEvent, DFSREvent, SysVolCheck, KccEvent, KnowsOfRoleHolders, MachineAccount, NCSecDesc, ObjectsReplicated, RidManager, VerifyReferences, 포리스트·도메인 DNS 영역, 스키마·구성 CrossRefValidation, LocatorCheck, Intersite)는 모두 passed였습니다.

cl11 계정을 다시 활성화한 뒤(10:54:21) 같은 날 14:06에 관리자 PowerShell에서 `dcdiag`를 다시 실행하자 SystemLog까지 모두 passed였습니다. 아래 화면은 같은 점검을 2026-11-04 21:31에 한 번 더 실행해 촬영한 것입니다(글꼴 20pt). 다만 SystemLog는 최근 60분만 읽으므로 원인 이벤트(10:46:30)가 이미 창 밖에 있던 시점의 결과이고, 이 통과만으로 조치 효과가 증명되지는 않습니다. 조치 뒤 상태는 6절 마지막 항목의 `nltest`·`dsregcmd` 조회로 확인했습니다. 화면의 맨 윗줄은 `whoami /groups`의 High Mandatory Level 줄로 관리자 권한 실행의 확인이고, 아래는 AD01 대상 테스트 16개와 전체 passed·failed 집계(passed 28, failed 0)입니다. 실행한 명령은 다음과 같습니다.

```powershell
whoami /groups | Select-String 'High Mandatory Level'
$r = dcdiag
$r | Select-String 'SIONNOTE-AD01 (passed|failed) test' | ForEach-Object { $_.Line.Trim() }
'passed: ' + @($r | Select-String 'passed test').Count + '   failed: ' + @($r | Select-String 'failed test').Count
```

[![관리자 권한 dcdiag 재실행(2026-11-04 21:31 촬영): passed 28, failed 0]({{ "/assets/images/2026/11/ad-hires-04-dcdiag-after-fix.png" | relative_url }})]({{ "/assets/images/2026/11/ad-hires-04-dcdiag-after-fix.png" | relative_url }}){:target="_blank"}

### 4. 운영 판단

- OU를 동기화 방식별로 나눈 것이 이 시리즈의 핵심 설계입니다. "어느 OU에 있는 계정·컴퓨터를 어느 동기화가 올리는가"를 OU 하나로 설명할 수 있어서, 하이브리드 조인 결과를 비교하기 쉬워집니다.
- `Admins` OU는 두 동기화 범위(ConnectSync·CloudSync OU) 밖에 있습니다. 이 OU의 계정은 Entra에 올라가지 않으므로, 하이브리드 조인한 PC에 이 계정으로 로그인하면 PRT가 나오지 않을 것으로 보입니다(추정, 뒤 글에서 사례를 다룸).
- AD 휴지통을 쓰지 않으므로 계정을 삭제하면 되돌릴 수 없습니다. 실습 중 삭제는 하지 않는 것을 기본으로 했습니다.

### 5. 절차


1. 서버 관리자 → 역할 및 기능 추가에서 **Active Directory 도메인 서비스**를 설치합니다(문서).
2. 결과 화면의 **이 서버를 도메인 컨트롤러로 승격**을 눌러 마법사를 엽니다(문서).
3. 배포 구성에서 **새 포리스트 추가**를 고르고 루트 도메인 이름을 입력합니다. 단일 레이블 이름은 쓸 수 없습니다(문서). DNS 서버·글로벌 카탈로그를 유지하고 DSRM 암호를 정합니다(문서).
4. 서버가 재시작되면 도메인 계정으로 로그인합니다. 이 랩에서 ad01의 컴퓨터 계정 암호가 마지막으로 설정된 시각이 2026-11-02 21:10이라, 승격은 그 무렵으로 보입니다(추정).

이후 OU와 사용자는 Active Directory 사용자 및 컴퓨터(ADUC)에서 만들었습니다.

### 6. 막힌 곳

- **일반 권한 셸에서 dcdiag가 4개 실패**: `whoami /groups`에 High Mandatory Level이 없는 상태(관리자 권한 아님)로 돌렸을 때 NetLogons·Replications·Services가 "접근 거부"로 실패했습니다. 문서도 dcdiag를 관리자 권한(elevated) 셸에서 실행하라고 안내합니다(문서). 관리자 권한으로 다시 열어 같은 명령을 실행하자 세 항목이 passed로 바뀌었습니다.
- **SystemLog 실패의 원인**: 이 테스트는 최근 60분 사이 System 로그의 오류·경고를 읽습니다(문서). 로그에는 SIONNOTE-CL11의 세션 설정이 "보안 데이터베이스에 신뢰 계정 SIONNOTE-CL11$ 없음"으로 실패한 이벤트(ID 0x165B)가 있었습니다. 이어서 컴퓨터 계정을 조회해 보니 CL11이 **비활성(Enabled=False)** 이었습니다.
- **비활성의 이유(추정)**: cl11은 Entra 조인을 시험할 때 작업 그룹으로 바꿔 도메인을 떠났습니다. 그 뒤 하이브리드 조인 상태의 체크포인트로 되돌렸는데, 되돌린 것은 PC의 디스크일 뿐 AD에 남은 컴퓨터 계정은 그대로라서 계정만 비활성 상태로 남은 것으로 보입니다. ad01의 보안 로그를 조회해 시점을 확인했습니다(조회, 2026-11-04 18:57). 컴퓨터 계정 `SIONNOTE-CL11$`는 11-04 09:29:49에 비활성화(이벤트 4725, 실행 계정 yadmin)됐고, 10:54:21에 활성화(4722)됐다가, 15:18:52에 다시 비활성화(4725)됐습니다. 같은 시각의 4742(컴퓨터 계정 변경)에서 계정 속성 값이 `0x80`→`0x81`(비활성 비트 추가)로 바뀐 것도 확인했습니다. 컴퓨터가 도메인을 떠날 때 도메인 자격 증명으로 계정이 비활성화되는 동작과 맞는 기록이며, 10:54의 활성화가 위 `Enable-ADAccount` 조치입니다(추정: 이벤트의 시각·실행 계정은 조회, 도메인 탈퇴가 원인이라는 연결은 추정). 15:18의 비활성화는 이 글의 11:30 시점 이후에 일어난 일이고 현재도 비활성 상태입니다(조회: `Get-ADComputer`). 이 로그의 가장 오래된 이벤트가 11-03 13:16이라 그보다 앞선 기록은 이 방법으로 볼 수 없습니다.

이벤트 뷰어의 보안 로그에서도 4725를 필터로 볼 수 있지만, 대상 계정 이름은 이벤트를 하나씩 열어야 보여서 PowerShell로 이벤트 XML의 필드를 읽었습니다.

```powershell
Get-WinEvent -FilterHashtable @{LogName='Security';Id=4725,4722,4742} | Sort-Object TimeCreated | ForEach-Object {
  $x=[xml]$_.ToXml(); $d=@{}; $x.Event.EventData.Data | ForEach-Object { $d[$_.Name]=$_.'#text' }
  if ($d['TargetUserName'] -match 'CL1') { '{0}  ID={1}  Target={2}  By={3}  UAC={4}->{5}' -f $_.TimeCreated.ToString('MM-dd HH:mm:ss'), $_.Id, $d['TargetUserName'], $d['SubjectUserName'], $d['OldUacValue'], $d['NewUacValue'] }
}
```

[![ad01 보안 로그의 SIONNOTE-CL10$·CL11$ 계정 이벤트(4722 활성화, 4725 비활성화, 4742 변경) 목록(PowerShell, 2026-11-04 21:26 다시 조회·촬영, 글꼴 24pt)]({{ "/assets/images/2026/11/ad-cl11-account-events.png" | relative_url }})]({{ "/assets/images/2026/11/ad-cl11-account-events.png" | relative_url }}){:target="_blank"}

참고로 cl10은 도메인 가입 전 단계의 체크포인트에서 갈라져 Entra 조인을 시험했기 때문에 도메인 가입 전 상태에서 시작해 작업 그룹으로 바꾸는 탈퇴 절차를 거치지 않았고, 컴퓨터 계정도 활성이었습니다(조회: 체크포인트 트리와 계정 `Enabled` 값). `Get-ADComputer`로 읽은 생성·변경 시각은 `SIONNOTE-CL10`이 11-03 3:28:25 PM 생성·11-03 3:46:29 PM 변경(11-04 변경 없음), `SIONNOTE-CL11`이 11-03 4:01:44 PM 생성·11-04 3:18:52 PM 변경(Enabled=False)입니다(조회, 2026-11-04 21:23). 이벤트 목록은 11-03 15:28 이후만 있고, 위 캡처의 4722 두 건(CL10 15:28:25, CL11 16:01:44)은 계정 생성 시각과 같습니다(조회).

- **조치와 결과**: 계정을 다시 활성화했습니다(`Enable-ADAccount`). 이후 cl11에서 `nltest /sc_query:sionnote.local`을 실행하자 트러스트된 DC가 ad01로 나오고 연결 상태가 `NERR_Success`였으며, `dsregcmd /status`는 AzureAdJoined·DomainJoined가 모두 YES, DeviceAuthStatus는 SUCCESS였습니다(조회). cl10도 같은 값(AzureAdJoined·DomainJoined YES)이었습니다. 이 글을 쓴 시점(2026-11-04 11:30경)에는 두 PC 모두 하이브리드 조인 상태로 정상이었습니다. 이후 Entra 조인 재현으로 상태가 바뀐 내용은 Entra 조인 글 7절에 있습니다.

### 7. 정리·남은 일

- 체크포인트를 적용한 클라이언트는 AD 계정 상태(Enabled, 암호 설정 시각)가 PC와 어긋날 수 있으니, 적용한 뒤 `Get-ADComputer`로 확인하는 것이 안전합니다.
- 다음 글: 동기화 서버(sync01)를 도메인에 가입시키는 과정.

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
