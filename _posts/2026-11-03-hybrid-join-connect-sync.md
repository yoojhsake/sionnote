---
title: "[IAM] Connect Sync로 하이브리드 조인 구성하기"
date: 2026-11-03 16:00:00 +0900
last_modified_at: 2026-11-05 00:40
categories: [iam]
phase: 하이브리드 실습
seq: 6
tags: [IAM, 하이브리드 조인, Entra Connect Sync, SCP, 장치 동기화, Windows 10]
excerpt: "Connect Sync 마법사의 장치 옵션으로 SCP를 만들고 Delta 동기화를 돌리면 도메인 가입 PC가 하이브리드 조인된다. 첫 조인은 실패하고 동기화 뒤 재시도에서 성공했다"
toc: true
---

도메인에 가입된 Windows 10 PC를 Entra ID에도 연결(하이브리드 조인)하려고 Connect Sync 마법사의 "장치 옵션 구성"을 실행했습니다. 마법사가 AD에 서비스 연결 지점(SCP)을 만들고, 컴퓨터 계정이 Entra로 동기화된 뒤 PC에서 조인 작업을 다시 실행하자 AzureAdJoined와 DomainJoined가 모두 YES가 됐습니다.

## 요약

- Connect Sync는 마법사 한 번으로 SCP를 만들고, 컴퓨터 계정은 기존 동기화 주기로 올림
- 첫 조인 시도는 실패하고, 장치가 Entra에 올라온 뒤 같은 작업을 다시 실행해야 성공함
- 마법사를 열어 두면 동기화 스케줄러가 멈추므로 끝나면 반드시 닫아야 함

> 근거 표기: 조회 = 이 랩에서 직접 읽은 값 · 문서 = Microsoft Learn · 확인 불가 = 시도했지만 확인하지 못한 값(방법·사유 병기) · 추정 = 조회·문서로 직접 확인하지 못하고 관찰값에서 이어 붙인 해석. 테넌트 ID·테넌트 도메인·클라우드 계정(UPN)은 가렸고, 개인 실습용 도메인(sionnote.local)의 계정 이름·장치 이름·호스트 이름은 그대로 보일 수 있습니다.

---

## 전체 기록

### 1. 목표

OU=ConnectSync에 있는 Windows 10 Enterprise(22H2) PC(sionnote-cl10)를 Connect Sync 경로로 하이브리드 조인합니다. 같은 서버(sionnote-sync01)에서 Cloud Sync도 돌고 있어서, 두 방식이 어떻게 다른지 비교하는 첫 번째 글입니다.

### 2. 개념

하이브리드 조인은 PC가 AD와 Entra ID 양쪽에 같은 장치로 등록되는 상태입니다. PC는 AD의 SCP에서 테넌트 정보를 찾아 자기 인증서를 컴퓨터 계정의 userCertificate에 쓰고, 동기화가 그 계정을 Entra에 올리면 조인을 끝냅니다(문서).

- **SCP**: PC가 자기 테넌트를 찾는 AD 객체. 이름은 Device Registration Configuration 컨테이너 아래에 있음
- **장치 동기화**: 컴퓨터 계정을 Entra에 "보류 중" 장치로 올리는 단계
- **Automatic-Device-Join**: PC에서 조인을 시도하는 예약 작업(작업 스케줄러의 Workplace Join 폴더)

### 3. 결과

#### 3-1. PC의 조인 상태

| 항목 | 조인 전 | 조인 후 |
|---|---|---|
| AD에 SCP | 없음(조회) | 있음, 테넌트 이름·ID 값이 들어 있음(조회) |
| AzureAdJoined | NO | YES |
| DomainJoined | YES | YES |
| DeviceAuthStatus | 해당 없음 | SUCCESS |

`dsregcmd /status` 결과를 캡처했습니다. 이 PC는 TpmProtected=NO, KeyProvider=소프트웨어 키인데, VM에 가상 TPM이 꺼져 있기 때문으로 보입니다(추정, [환경 글]({{ "/iam/hyperv-lab-environment/" | relative_url }}) 참고).

**GUI로 본 PC 쪽 상태**: 설정 → 계정 → **회사 또는 학교 액세스**에는 "SIONNOTE AD 도메인에 연결됨(sionnote.local)"만 보입니다(조회, 2026-11-04). 이 화면으로는 Entra 쪽 등록 여부를 알 수 없어서 `dsregcmd`와 Entra 포털의 장치 목록으로 확인합니다.

[![cl10 설정 > 회사 또는 학교 액세스(GUI)]({{ "/assets/images/2026/11/hj-cl10-gui-01-work-school.png" | relative_url }})]({{ "/assets/images/2026/11/hj-cl10-gui-01-work-school.png" | relative_url }}){:target="_blank"}

조인을 시도하는 예약 작업은 **작업 스케줄러**(`taskschd.msc`) → 작업 스케줄러 라이브러리 → Microsoft → Windows → **Workplace Join**의 `Automatic-Device-Join`입니다. 아래 화면은 상태 "준비", 마지막 실행 2026-11-04 11:28:23, 결과 "작업을 완료했습니다(0x0)"입니다(조회).

[![cl10 작업 스케줄러: Workplace Join > Automatic-Device-Join(GUI)]({{ "/assets/images/2026/11/hj-cl10-gui-02-task-scheduler.png" | relative_url }})]({{ "/assets/images/2026/11/hj-cl10-gui-02-task-scheduler.png" | relative_url }}){:target="_blank"}

`dsregcmd /status`의 값은 PowerShell로만 볼 수 있습니다(GUI 없음). 글꼴을 키워 다시 찍은 화면입니다(cl10, `sionnote\yadmin`, 2026-11-04). 장치 ID·테넌트 값은 출력에서 제외했습니다.

```powershell
whoami
dsregcmd /status | Select-String 'AzureAdJoined|EnterpriseJoined|DomainJoined|DomainName|KeyProvider|TpmProtected|DeviceAuthStatus|NgcSet|AzureAdPrt '
```

[![cl10 dsregcmd 결과(글꼴 확대, 2026-11-04)]({{ "/assets/images/2026/11/hj-cl10-dsreg-hybrid-hires.png" | relative_url }})]({{ "/assets/images/2026/11/hj-cl10-dsreg-hybrid-hires.png" | relative_url }}){:target="_blank"}

이 PC에 로그인한 `yadmin`은 동기화 범위 밖(Admins OU)이고 `AzureAdPrt`는 NO였습니다. 범위 밖이라는 점은 조회했습니다. 같은 PC(cl10)에서 yadmin으로 다시 로그온한 1건(2026-11-05 00:01)에서는 AAD Operational 로그에 AADSTS90002(UPN 접미사 `.local`에 해당하는 테넌트 없음)가 남았습니다(조회, 캡처는 별도 글). 아래는 조인 직후(11-03)에 옮겨 적은 출력입니다.

**사용한 명령과 출력** — cl10의 관리자 PowerShell에서 실행했고, 장치 ID·테넌트 ID는 적지 않았습니다(화면에서 옮겨 적음).

```powershell
dsregcmd /status
```

```text
      AzureAdJoined : YES
   EnterpriseJoined : NO
       DomainJoined : YES
         DomainName : SIONNOTE
        KeyProvider : Microsoft Software Key Storage Provider
       TpmProtected : NO
   DeviceAuthStatus : SUCCESS
              NgcSet : NO
        WamDefaultSet : NO
         AzureAdPrt : NO
```

<details markdown="1">
<summary>원본 캡처 보기 (PowerShell 화면, 해상도 낮음)</summary>

[![하이브리드 조인 후 dsregcmd 결과]({{ "/assets/images/2026/11/hj-cl10-dsreg-hybrid.png" | relative_url }})]({{ "/assets/images/2026/11/hj-cl10-dsreg-hybrid.png" | relative_url }}){:target="_blank"}

</details>

### 4. 운영 판단

- 마법사는 AD에 쓰는 일(SCP 생성)이라서 Enterprise Admins 권한의 계정이 한 번 필요합니다. 포털 로그인 계정은 하이브리드 ID 관리자 이상이 필요하다고 문서에 나옵니다(문서).
- 컴퓨터 계정이 동기화 범위(도메인·OU 필터)에 들어 있어야 합니다. 마법사 화면에도 같은 안내가 있습니다. 이 랩은 설치 때 Domain/OU Filtering에서 `ConnectSync` OU만 선택했고([설치 글]({{ "/iam/connect-sync-install-firewall/" | relative_url }})의 필터 화면), cl10의 컴퓨터 계정이 그 OU에 있어서 장치가 Entra에 올라왔습니다(조회).
- 기본 Delta 동기화 주기는 문서 기준 30분입니다. 테스트는 수동으로 Delta를 실행해 기다리지 않았습니다.

### 5. 절차

사전 상태는 PC가 도메인에 가입되어 있고 OU=ConnectSync에 있는 것입니다. AD에는 SCP가 아직 없었습니다(조회: 존재 확인이 False).

1. sync01에서 Microsoft Entra Connect 마법사를 열고 **Configure → Additional tasks → Configure device options**를 선택합니다.
2. Overview를 읽고 Next를 누릅니다. 로그인 창에서 테넌트 관리자 계정으로 로그인합니다(자격 증명은 직접 입력).
3. Device options에서 **Configure Hybrid Microsoft Entra ID join**을 선택합니다.
4. Device operating systems에서 **Windows 10 or later domain-joined devices**를 체크합니다.
5. SCP configuration에서 포리스트를 체크하고, Authentication Service를 **Microsoft Entra ID**로 고르고, Enterprise Admin 열에서 Enterprise Admins 계정의 자격 증명을 입력합니다.
6. Ready to configure에서 Configure를 누르고 Configuration complete까지 확인한 뒤 **Exit**로 마법사를 닫습니다.
7. sync01에서 Delta 동기화를 실행합니다.

**GUI로 동기화 결과 확인**: 시작 → **Synchronization Service Manager**(`C:\Program Files\Microsoft Azure AD Sync\UIShell\miisclient.exe`) → **Operations** 탭에서 커넥터별 Delta Import, Delta Synchronization, Export의 상태(Status)와 시작·종료 시각을 봅니다. 아래 화면(조회, 2026-11-04)은 커넥터 두 개(Name 열은 테넌트 이름이 섞여 있어 전체를 가림, 프로파일마다 두 행씩 쌍으로 나옴)가 오후 10:56, 11:26, 11:56(캡처의 Start Time 열)에 각각 Delta Import → Delta Synchronization → Export를 한 번씩 돌고 모두 success였다는 것을 보여 줍니다. 두 커넥터가 AD용과 Entra용이라는 것은 문서의 구성 설명에 따른 것입니다(문서). 30분 간격이라 문서의 기본 Delta 주기와 맞습니다(문서, 위 4절).

[![Synchronization Service Manager > Operations: 30분 간격 Delta 주기가 모두 success(GUI, Name 열은 테넌트 도메인이 섞여 있어 전체를 가림)]({{ "/assets/images/2026/11/hj-connect-gui-01-sync-operations.png" | relative_url }})]({{ "/assets/images/2026/11/hj-connect-gui-01-sync-operations.png" | relative_url }}){:target="_blank"}

PowerShell로는 아래처럼 합니다(수동 실행, 스케줄러 확인).

```powershell
Get-ADSyncScheduler | fl SyncCycleEnabled,SchedulerSuspended,NextSyncCyclePolicyType
Start-ADSyncSyncCycle -PolicyType Delta
```

출력(화면에서 옮겨 적음, sync01 관리자 PowerShell)입니다.

```text
SyncCycleEnabled        : True
SchedulerSuspended      : False
NextSyncCyclePolicyType : Delta

Result
------
Success
```

<details markdown="1">
<summary>캡처 보기 (같은 명령을 2026-11-05 00:12에 sync01에서 다시 실행한 PowerShell 화면. 시각·호스트는 작업 기록 기준이며 캡처에는 표시되지 않음)</summary>

[![같은 명령 재실행(2026-11-05): SyncCycleEnabled True, Delta 동기화 Result Success]({{ "/assets/images/2026/11/hj-connect-04-delta.png" | relative_url }})]({{ "/assets/images/2026/11/hj-connect-04-delta.png" | relative_url }}){:target="_blank"}

</details>

PC에서 SCP를 읽을 수 있는지와 조인 작업 결과는 다음으로 확인합니다.

```powershell
$scp = 'LDAP://CN=62a0ff2e-97b9-4513-943f-0d221bd30080,CN=Device Registration Configuration,CN=Services,CN=Configuration,DC=sionnote,DC=local'
[ADSI]::Exists($scp)        # True
([ADSI]$scp).keywords       # azureADName:..., azureADId:...

$p = '\Microsoft\Windows\Workplace Join\'
Get-ScheduledTask -TaskPath $p -TaskName 'Automatic-Device-Join' | ft TaskPath,TaskName,State   # 작업 상태 확인
Start-ScheduledTask -TaskPath $p -TaskName 'Automatic-Device-Join'
Start-Sleep 40
Get-ScheduledTaskInfo -TaskPath $p -TaskName 'Automatic-Device-Join' | fl LastRunTime,LastTaskResult   # 0 = 성공
dsregcmd /status | Select-String 'AzureAdJoined|DomainJoined|DeviceAuthStatus'
```

PC(cl10)에서 SCP를 확인한 출력입니다. 테넌트 이름·ID가 든 `keywords` 줄은 가렸습니다.

```text
SCP exists: True
azureADName:  (가림)
azureADId:    (가림)

TaskPath                            TaskName              State
--------                            --------              -----
\Microsoft\Windows\Workplace Join\  Automatic-Device-Join Ready
```

<details markdown="1">
<summary>캡처 보기 (같은 확인을 2026-11-05 00:13에 cl10에서 다시 실행한 PowerShell 화면. 시각·호스트는 작업 기록 기준이며 캡처에는 표시되지 않음)</summary>

[![SCP 재확인(2026-11-05): SCP exists True, 테넌트 키워드 값은 가림, Automatic-Device-Join Ready]({{ "/assets/images/2026/11/hj-connect-03-scp-check.png" | relative_url }})]({{ "/assets/images/2026/11/hj-connect-03-scp-check.png" | relative_url }}){:target="_blank"}

</details>

### 6. 막힌 곳

- **마법사 SCP 단계의 오류**: 포리스트만 체크하고 Next를 누르면 인증 서비스나 Enterprise Admin 자격 증명이 없다는 오류가 납니다. Authentication Service를 고르고 자격 증명을 넣으면 사라졌습니다(조회).
- **첫 조인 실패**: SCP를 만든 직후 조인 작업을 실행하자 0x801c03f3(error_missing_device)로 실패했습니다. 장치가 Entra에 올라온 뒤 다시 실행해 성공했고, 원인과 순서는 [하이브리드 조인이 0x801c03f3으로 실패할 때]({{ "/iam/troubleshooting/hybrid-join-0x801c03f3/" | relative_url }})에 따로 적었습니다.
- **도메인에 다시 가입한 뒤 0x801c005b로 실패(2026-11-04)**: cl10을 다시 도메인에 가입시키자 error_missing_device가 아니라 0x801c005b(error_computer_signature_check_failure)로 실패했습니다(조회, 이 한 건에서 확인). 캡처와 감사 로그는 이 장 끝의 "0x801c005b 사례" 소절에 있습니다.
- **스케줄러 중지**: 마법사 첫 화면에 "마법사가 닫힐 때까지 동기화 스케줄러가 중지"된다는 안내가 있습니다(조회). Exit 뒤 SchedulerSuspended가 False인 것을 확인했습니다.

#### 0x801c005b 사례 (cl10, 2026-11-04)

이 PC(cl10)는 같은 날 Entra 조인 실습에도 쓰였고 체크포인트로 되돌린 적이 있습니다([Entra 조인 글]({{ "/iam/entra-join-cl10-cl11/" | relative_url }}) 참고). 이 이력 때문에 도메인 재가입 직전까지의 조작 순서를 한 줄로 단정하지 않고, 도메인에 다시 가입시킨 뒤 읽은 값만 적습니다. 그 PC에서 `dsregcmd`가 0x801c005b(invalid_request, error_computer_signature_check_failure)를 냈습니다(조회). 네트워크·DC 쪽은 정상이었습니다. `nltest /dsgetdc:sionnote.local`은 DC sionnote-ad01을 찾았고 `/sc_query`는 NERR_Success(0)였습니다.

[![cl10 nltest: DC 탐색과 보안 채널 쿼리 성공]({{ "/assets/images/2026/11/hj-cl10-nltest.png" | relative_url }})]({{ "/assets/images/2026/11/hj-cl10-nltest.png" | relative_url }}){:target="_blank"}

[![cl10 dsregcmd: AzureAdJoined NO, DomainJoined YES, 0x801c005b, error_computer_signature_check_failure]({{ "/assets/images/2026/11/hj-fail-801c005b-cl10.png" | relative_url }})]({{ "/assets/images/2026/11/hj-fail-801c005b-cl10.png" | relative_url }}){:target="_blank"}

Previous Registration 항목에는 Registration Type이 sync, Server Operation이 DeviceRenew로 남아 있었고, 메시지는 "도메인 <테넌트>의 장치 <ID>에 대한 서명 검증에 실패했다"는 내용이었습니다(조회, 장치 ID·테넌트 ID는 가림). 이 값만으로는 신규 등록(Join)과 갱신(Renew)을 구분하지 못합니다. 첫 조인 실패 때의 이벤트도 같은 DeviceRenew로 기록되기 때문입니다([0x801c03f3 글]({{ "/iam/troubleshooting/hybrid-join-0x801c03f3/" | relative_url }}) 참고, 조회).

[![Previous Registration: Registration Type sync, Server Operation DeviceRenew, 서명 검증 실패 메시지]({{ "/assets/images/2026/11/hj-cl10-prev-registration.png" | relative_url }})]({{ "/assets/images/2026/11/hj-cl10-prev-registration.png" | relative_url }}){:target="_blank"}

Entra 관리 센터의 장치 목록에는 sionnote-cl10 하이브리드 레코드(등록 2026-11-03 15:56:35)가 그대로 남아 있었고, 이 레코드의 장치 ID가 위 메시지의 ID와 같았습니다(조회). 이 PC가 가진 키와 레코드의 키가 맞지 않아 서명 검증이 실패한 것으로 판단했습니다(추정: 서명 검증 실패 메시지와 레코드 ID 일치에서 판단한 것이고, 서버 쪽에서 키를 비교한 값은 읽지 못했습니다). 같은 시각대 감사 로그에는 이름이 가려진 `DESKTOP-…` 장치의 Unregister·Delete 기록(22:11:41)이 있는데, 이는 이 글의 `sionnote-cl10` 레코드와 다른 장치입니다(조회, 대상 이름이 달라서 구분).

[![Entra 장치 목록: 이전 하이브리드 레코드가 남아 있음]({{ "/assets/images/2026/11/hj-cl10-entra-stale-record.png" | relative_url }})]({{ "/assets/images/2026/11/hj-cl10-entra-stale-record.png" | relative_url }}){:target="_blank"}

Automatic-Device-Join의 마지막 실행은 22:19:43, 결과 0x1이었습니다.

[![작업 스케줄러: Automatic-Device-Join 마지막 실행 결과 0x1]({{ "/assets/images/2026/11/hj-cl10-task-adj-fail.png" | relative_url }})]({{ "/assets/images/2026/11/hj-cl10-task-adj-fail.png" | relative_url }}){:target="_blank"}

이 레코드를 Entra에서 삭제하고(22:25:45) 작업을 다시 실행했습니다(22:27:22, 결과 0x0). 감사 로그에는 삭제 직후 22:26:28에 Connect Sync(ConnectSyncProvisioning)가 같은 장치를 Restore device로 되살린 기록과, 22:27:41에 Device Registration Service의 Update device가 이어서 있습니다(조회). 복원된 장치의 ID가 이전 ID와 같다는 점은 비공개 값이라 화면에 싣지 않았습니다(조회). 순서는 삭제 → 복원 → 재실행에서 PC의 갱신 성공입니다. 삭제 43초 뒤에 복원된 것은 동기화 주기가 그 사이에 돌았다는 뜻인데, 수동으로 실행했는지 예약 주기였는지는 확인 불가입니다. 방법은 작업 기록 대조였고, 사유는 그 시각에 동기화 실행 명령을 남기지 않았기 때문입니다. 삭제와 재실행 중 어느 쪽이 결정적이었는지는 확인 불가입니다. 방법은 삭제 전에 재실행해 보는 것인데, 이미 삭제한 뒤에 조치를 진행해 같은 상태에서 비교하지 못했고, 다시 만들려면 도메인 재가입을 한 번 더 해야 해서 이번에는 하지 않았습니다.

[![감사 로그: 삭제 → Restore device(ConnectSync) → Update device(Device Registration Service)]({{ "/assets/images/2026/11/hj-cl10-audit-delete-restore-update.png" | relative_url }})]({{ "/assets/images/2026/11/hj-cl10-audit-delete-restore-update.png" | relative_url }}){:target="_blank"}

재실행 뒤 `dsregcmd`는 AzureAdJoined YES, DomainJoined YES, DeviceAuthStatus SUCCESS입니다(조회). TenantName 줄은 값이 비어 있었습니다.

[![재실행 뒤 dsregcmd: AzureAdJoined YES, DomainJoined YES, DeviceAuthStatus SUCCESS, TenantName 빈 값]({{ "/assets/images/2026/11/hj-cl10-after-rerun-dsreg.png" | relative_url }})]({{ "/assets/images/2026/11/hj-cl10-after-rerun-dsreg.png" | relative_url }}){:target="_blank"}


### 7. 정리·남은 일

- 같은 PC를 Entra 조인(클라우드 조인)과 비교하는 글에서 이어서 다룹니다. Cloud Sync로 같은 일을 하는 방법은 [다음 글]({{ "/iam/hybrid-join-cloud-sync/" | relative_url }})에 있습니다.

## 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (5건)</summary>

- **조회**: 마법사 화면 순서(Additional tasks, Device options, Device operating systems, SCP configuration, Ready to configure, Configuration complete)와 SCP 단계의 오류 문구
    - 출처: sionnote-sync01 (2026-11-03)
- **조회**: Delta 동기화 결과 Success, SCP 존재 True와 azureADName/azureADId 값
    - 출처: sionnote-sync01, sionnote-cl10 (PowerShell)
- **조회**: 조인 작업 LastTaskResult 0, AzureAdJoined YES, DomainJoined YES, DeviceAuthStatus SUCCESS
    - 출처: sionnote-cl10 (dsregcmd /status)
- **조회**: 도메인 재가입 뒤 0x801c005b 실패, Previous Registration(DeviceRenew), Entra 레코드 ID 일치, 삭제·Restore device·Update device 감사 로그 순서, 재실행 결과 0x0
    - 출처: sionnote-cl10 (nltest, dsregcmd /status, 작업 스케줄러), Entra 관리 센터(장치, 감사 로그) (2026-11-04)
- **문서**: 하이브리드 조인 구성과 확인 방법
    - 출처: [Configure Microsoft Entra hybrid join](https://learn.microsoft.com/entra/identity/devices/how-to-hybrid-join), [Verify Microsoft Entra hybrid join](https://learn.microsoft.com/entra/identity/devices/how-to-hybrid-join-verify)

</details>
