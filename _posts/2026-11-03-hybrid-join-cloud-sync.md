---
title: "[IAM] Cloud Sync로 하이브리드 조인 구성하기"
date: 2026-11-03 17:00:00 +0900
last_modified_at: 2026-11-05 00:40
categories: [iam]
phase: 하이브리드 실습
seq: 7
tags: [IAM, 하이브리드 조인, Entra Cloud Sync, 장치 동기화, 요청 시 프로비전, Windows 11]
excerpt: "Cloud Sync는 포털에서 디바이스 동기화를 켜는 것만으로 컴퓨터 계정을 Entra에 올린다. 요청 시 프로비전의 오류 문구와 달리 장치는 보류 중으로 생성됐고, 재시도에서 조인이 끝났다"
toc: true
---

Cloud Sync 쪽 PC(Windows 11)를 하이브리드 조인하려고 포털에서 디바이스 동기화를 켰습니다. 서버에 마법사를 돌리지 않고 구성 속성의 체크박스 하나와 요청 시 프로비전으로 장치를 Entra에 올렸고, PC에서 조인 작업을 다시 실행하자 AzureAdJoined와 DomainJoined가 모두 YES가 됐습니다.

## 요약

- Cloud Sync의 장치 동기화는 이 랩에서 처음에 꺼져 있었고(조회), 구성 속성에서 켰음
- 요청 시 프로비전 화면에 오류 문구가 떠도 장치 목록에 "보류 중"으로 생기면 성공함
- Connect Sync 쪽에서 만든 SCP를 Cloud Sync 경로의 PC도 그대로 써서 조인됨(조회)

> 근거 표기: 조회 = 이 랩에서 직접 읽은 값 · 문서 = Microsoft Learn · 확인 불가 = 시도했지만 확인하지 못한 값(방법·사유 병기) · 추정 = 조회·문서로 직접 확인하지 못하고 관찰값에서 이어 붙인 해석. 테넌트 ID·테넌트 도메인·클라우드 계정(UPN)은 가렸고, 개인 실습용 도메인(sionnote.local)의 계정 이름·장치 이름·호스트 이름은 그대로 보일 수 있습니다.

---

## 전체 기록

### 1. 목표

OU=CloudSync에 있는 Windows 11 Enterprise PC(sionnote-cl11)를 Cloud Sync 경로로 하이브리드 조인합니다. [Connect Sync 글]({{ "/iam/hybrid-join-connect-sync/" | relative_url }})과 같은 서버에서 비교하는 두 번째 글입니다.

### 2. 개념

Cloud Sync는 동기화 구성과 실행 계획이 포털(클라우드)에 있고, 서버에는 가벼운 프로비저닝 에이전트만 설치합니다(문서). 컴퓨터 계정을 올리는 일은 AD to Microsoft Entra ID 구성 안의 장치 동기화(AD2AADDeviceSync 작업)가 맡습니다(문서).

- **디바이스 동기화**: 이 랩에서는 처음에 사용 안 함이었고(조회), 켜면 범위 안의 컴퓨터 계정을 Entra로 보냅니다(문서: Configure device sync with Microsoft Entra Cloud Sync)
- **요청 시 프로비전**: 사용자나 장치 한 개를 지금 바로 동기화해 보는 포털 기능
- **SCP**: 포리스트에 만들어 두는 객체이고, 이 랩에서는 Connect Sync 쪽에서 만든 것을 Cloud Sync 경로가 그대로 썼습니다(조회). 두 방식이 한 개를 공유하는 것이 공식 요건인지는 문서를 찾지 못해 이 랩의 관찰로만 적습니다

### 3. 결과

#### 3-1. PC의 조인 상태

| 항목 | 값 |
|---|---|
| 디바이스 동기화(포털 속성) | 사용 안 함 → 사용 |
| 장치 목록의 등록됨 열 | 보류 중 → 조인 후 날짜 |
| AzureAdJoined / DomainJoined | YES / YES |
| DeviceAuthStatus | SUCCESS |

**GUI로 본 PC 쪽 상태**: 설정 → 계정 → **회사 또는 학교 액세스**에는 `sionnote.local`, "SIONNOTE AD 도메인에 연결됨"이 보입니다(조회, 2026-11-04). 도메인 연결만 보이고 Entra 등록 여부는 이 화면에 나오지 않아서 `dsregcmd`와 Entra 포털의 장치 목록으로 확인합니다.

[![cl11 설정 > 회사 또는 학교 액세스(GUI)]({{ "/assets/images/2026/11/hj-cl11-gui-01-work-school.png" | relative_url }})]({{ "/assets/images/2026/11/hj-cl11-gui-01-work-school.png" | relative_url }}){:target="_blank"}

조인 예약 작업은 **작업 스케줄러**(`taskschd.msc`) → 작업 스케줄러 라이브러리 → Microsoft → Windows → **Workplace Join**의 `Automatic-Device-Join`입니다. 상태 "준비", 마지막 실행 2026-11-04 오후 1:19:25, 결과 "작업을 완료했습니다(0x0)"입니다(조회).

[![cl11 작업 스케줄러: Workplace Join > Automatic-Device-Join(GUI)]({{ "/assets/images/2026/11/hj-cl11-gui-02-task-scheduler.png" | relative_url }})]({{ "/assets/images/2026/11/hj-cl11-gui-02-task-scheduler.png" | relative_url }}){:target="_blank"}

`dsregcmd /status`는 PowerShell로만 볼 수 있습니다. 글꼴을 키워 다시 찍은 화면입니다(cl11, `sionnote\yadmin`, 2026-11-04, 장치 ID·테넌트 값 제외). 관리자 계정으로 로그인한 세션의 값이라 AzureAdPrt가 NO이고, 그 원인은 [PRT 글]({{ "/iam/troubleshooting/hybrid-join-prt-no/" | relative_url }})에 정리했습니다. 직접 원인(UPN 접미사 `.local`)을 이벤트 로그로 확인한 것은 cl10의 로그온 1건입니다(PRT 글 참고). cl11은 가상 TPM이 켜져 있고(조회) KeyProvider가 Platform Crypto Provider, TpmProtected가 YES입니다(조회).

```powershell
whoami
dsregcmd /status | Select-String 'AzureAdJoined|EnterpriseJoined|DomainJoined|DomainName|KeyProvider|TpmProtected|DeviceAuthStatus|NgcSet|AzureAdPrt '
```

[![cl11 dsregcmd 결과(글꼴 확대, 2026-11-04)]({{ "/assets/images/2026/11/hj-cl11-dsreg-hybrid-hires.png" | relative_url }})]({{ "/assets/images/2026/11/hj-cl11-dsreg-hybrid-hires.png" | relative_url }}){:target="_blank"}

아래는 조인 직후(11-03)에 옮겨 적은 출력입니다.

**사용한 명령과 출력** — cl11의 관리자 PowerShell에서 아래 5절의 조인 작업 실행·확인 명령을 돌린 결과입니다(화면에서 옮겨 적음, 2026-11-03).

```text
LastRunTime    : 2026-11-03 오후 4:11:11
LastTaskResult : 0

      AzureAdJoined : YES
       DomainJoined : YES
   DeviceAuthStatus : SUCCESS
```

`LastTaskResult`가 0이면 작업이 성공으로 끝났다는 뜻이고, 그 뒤 `dsregcmd`가 하이브리드 조인 상태를 보여 줍니다.

<details markdown="1">
<summary>원본 캡처 보기 (PowerShell 화면, 해상도 낮음)</summary>

[![하이브리드 조인 후 dsregcmd 결과(Cloud Sync 경로)]({{ "/assets/images/2026/11/hj-cl11-dsreg-hybrid.png" | relative_url }})]({{ "/assets/images/2026/11/hj-cl11-dsreg-hybrid.png" | relative_url }}){:target="_blank"}

</details>

#### 3-2. 포털 구성 확인(2026-11-04 조회)

| 화면 | 확인한 값 |
|---|---|
| 구성 개요 | 암호 해시 동기화 사용, **디바이스 동기화 사용**, Exchange 하이브리드 쓰기 저장 사용 안 함, 에이전트 1 사용, 장치 동기화 상태 컴퓨터 1건 100% 완료 |
| 속성 > 기본 | 실수로 인한 삭제 방지 사용, 삭제 임계값 500 |
| 필터 범위 지정 | **선택한 조직 구성 단위 동기화**: `OU=CloudSync,OU=CloudSyncLab,DC=sionnote,DC=local` 하나 |
| 에이전트 | `sionnote-sync01.sionnote.local` 활성(외부 IP는 가림) |

[![구성 개요: 디바이스 동기화 사용, 에이전트 1, 컴퓨터 1건 동기화]({{ "/assets/images/2026/11/cs-portal-01-overview.png" | relative_url }})]({{ "/assets/images/2026/11/cs-portal-01-overview.png" | relative_url }}){:target="_blank"}

[![필터 범위 지정: OU=CloudSync만 선택]({{ "/assets/images/2026/11/cs-portal-02-scope.png" | relative_url }})]({{ "/assets/images/2026/11/cs-portal-02-scope.png" | relative_url }}){:target="_blank"}

[![에이전트: sync01 활성]({{ "/assets/images/2026/11/cs-portal-03-agents.png" | relative_url }})]({{ "/assets/images/2026/11/cs-portal-03-agents.png" | relative_url }}){:target="_blank"}

범위가 OU 하나라서, 앞 글의 OU 설계대로 **컴퓨터 계정이 `OU=CloudSync`에 있는 cl11만** 이 구성으로 장치 동기화됩니다.

### 4. 운영 판단

- 포털에서 구성하는 계정은 하이브리드 ID 관리자 이상이 필요하다고 문서에 나옵니다. 프로비저닝 에이전트는 1.1.1107 이상이어야 합니다(문서).
- SCP를 새로 만들어야 하면 문서의 ConfigureSCP.ps1을 Enterprise Admins 계정으로 실행합니다. 이 랩은 Connect Sync 쪽에서 SCP를 이미 만들어서 이 단계를 하지 않았고, SCP가 있는 것만 확인했습니다(조회).
- 범위는 구성의 "필터 범위 지정"을 따릅니다. 이 랩은 OU=CloudSync 하나만 범위에 있고, PC의 컴퓨터 계정을 그 OU에 두었습니다(조회).

### 5. 절차

1. Entra 관리 센터 → Entra ID → Entra Connect → **Cloud sync**에서 구성(sionnote.local)을 엽니다.
2. **속성 → 기본**에서 디바이스 동기화가 사용 안 함인지 확인합니다.
3. 기본의 편집(연필) 아이콘을 열고 **디바이스 동기화 사용**을 체크한 뒤 적용합니다. 알림에 "속성이 업데이트되었습니다"가 뜹니다.
4. **요청 시 프로비전 → 디바이스 탭**에 컴퓨터의 고유 이름(DN)을 입력하고 프로비전합니다.
5. **Entra ID → 장치 → 모든 디바이스**에서 PC가 "보류 중"으로 보이는지 확인합니다(조인이 끝나면 등록 날짜가 표시됩니다).
6. PC에서 Automatic-Device-Join을 다시 실행하고 `dsregcmd /status`로 확인합니다.

[![속성 > 기본: 디바이스 동기화 "사용"(2026-11-04 조회)]({{ "/assets/images/2026/11/hj-cloud-02-enable.png" | relative_url }})]({{ "/assets/images/2026/11/hj-cloud-02-enable.png" | relative_url }}){:target="_blank"}

[![요청 시 프로비전 > 디바이스 탭: 컴퓨터의 고유 이름(DN)을 입력하는 칸]({{ "/assets/images/2026/11/hj-cloud-03-ondemand.png" | relative_url }})]({{ "/assets/images/2026/11/hj-cloud-03-ondemand.png" | relative_url }}){:target="_blank"}

[![모든 디바이스(2026-11-04 오전): 하이브리드 cl10·cl11과 함께 Entra 조인 cl11(9:52)·DESKTOP-…(9:19)이 보임. 같은 날 오후 Entra 조인 재현으로 레코드가 바뀌었습니다]({{ "/assets/images/2026/11/hj-cloud-04-devices.png" | relative_url }})]({{ "/assets/images/2026/11/hj-cloud-04-devices.png" | relative_url }}){:target="_blank"}

```text
CN=SIONNOTE-CL11,OU=CloudSync,OU=CloudSyncLab,DC=sionnote,DC=local
```

PC에서 쓰는 명령은 Connect Sync 글과 같습니다.

```powershell
$p = '\Microsoft\Windows\Workplace Join\'
Start-ScheduledTask -TaskPath $p -TaskName 'Automatic-Device-Join'
Start-Sleep 40
Get-ScheduledTaskInfo -TaskPath $p -TaskName 'Automatic-Device-Join' | fl LastRunTime,LastTaskResult   # 0 = 성공
dsregcmd /status | Select-String 'AzureAdJoined|DomainJoined|DeviceAuthStatus'
```

### 6. 막힌 곳

- **요청 시 프로비전 오류 문구**: 프로비전을 누르면 "요청에 대한 변경 요약 이벤트를 내보내지 않았다"는 오류 문구가 떴습니다. 그런데 같은 시각 장치 목록에는 PC가 "보류 중"으로 생겼습니다(조회). 판단은 이 문구가 아니라 장치 목록으로 해야 했습니다.
- **첫 조인 실패**: 장치가 올라오기 전에 조인 작업을 실행하면 0x801c03f3으로 실패합니다. 상세는 [하이브리드 조인이 0x801c03f3으로 실패할 때]({{ "/iam/troubleshooting/hybrid-join-0x801c03f3/" | relative_url }})에 있습니다.
- **삭제한 장치가 되살아나는 동작**: cl11에서 Entra 감사 로그를 시간순으로 읽으면, 2026-11-04 21:48:46에 장치 레코드가 Unregister/Delete 되었고 21:54:59에 Microsoft.Azure.SyncFabric(Cloud Sync)이 sionnote-cl11을 Restore device로 복원했으며, 22:01:55 전후로 Device Registration Service의 Update device가 이어졌습니다(조회, 감사 로그). 감사 로그에는 오후 3:34:58에도 같은 장치의 Restore device가 Failure로 한 번 기록되어 있습니다(조회, 행위자 SyncFabric. 실패 사유는 읽지 않았습니다). 같은 상황을 Connect Sync 경로(cl10)에서는 ConnectSyncProvisioning이 복원했습니다([Connect Sync 글]({{ "/iam/hybrid-join-connect-sync/" | relative_url }})의 0x801c005b 사례). 공식 문서는 다른 사람이 지운 장치를 AD 개체가 바뀌지 않는 한 Cloud Sync가 다시 만들지 않는다고 설명하는데(문서), 이 실습에서는 복원이 관찰되었습니다. 두 내용이 어긋나는 이유는 확인 불가입니다. 감사 로그에는 복원을 일으킨 원인이 기록되지 않았고, AD 개체 변경 이력은 조회하지 않았기 때문입니다. 도메인 가입 직후라 컴퓨터 계정에 변경이 있었을 가능성은 있습니다(추정). 복원 뒤(22:01:55)에 조인 작업을 재실행하자 결과가 0x0이었습니다(조회).
- **개요 화면의 장치 상태**: 디바이스 동기화를 켠 직후에는 "초기 동기화가 실행되지 않음"으로 보였고, 얼마 뒤 컴퓨터 1건이 100% 완료로 바뀌었습니다(조회).

### 7. 정리·남은 일

- 장치 동기화 전용 주기는 Learn의 device-sync 문서에 적혀 있지 않았습니다(시도: 문서 전문 확인). 참고로 Cloud Sync FAQ는 사용자·그룹 프로비전이 약 10~20분 주기라고 안내합니다(문서). 사용자·그룹 주기를 장치에 그대로 적용할 수는 없지만, 이 랩에서는 요청 시 프로비전으로 올린 컴퓨터가 바로 "보류 중"으로 보였습니다(조회). 그래서 조인 지연을 줄이는 방법으로 요청 시 프로비전을 권합니다(추정: 일반적인 주기와의 차이는 비교하지 못함).
- 사용자 PRT까지 확인한 결과는 [하이브리드 조인 후 AzureAdPrt가 NO일 때]({{ "/iam/troubleshooting/hybrid-join-prt-no/" | relative_url }})에 정리했습니다.

## 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (6건)</summary>

- **문서**: 디바이스 동기화 구성(에이전트 1.1.1107 이상, 하이브리드 ID 관리자 이상, 요청 시 프로비전 절차)
    - 출처: [Configure device sync with Microsoft Entra Cloud Sync](https://learn.microsoft.com/entra/identity/hybrid/cloud-sync/device-sync)
- **문서**: Cloud Sync가 컴퓨터 계정을 동기화해 하이브리드 조인이 가능하다는 설명
    - 출처: [What is Microsoft Entra Cloud Sync?](https://learn.microsoft.com/entra/identity/hybrid/cloud-sync/what-is-cloud-sync)
- **문서**: 사용자·그룹 프로비전은 약 10~20분 주기, 암호 해시 동기화는 2~5분 주기
    - 출처: [Microsoft Entra Cloud Sync FAQ](https://learn.microsoft.com/entra/identity/hybrid/cloud-sync/reference-cloud-sync-faq)
- **조회**: 속성 > 기본의 디바이스 동기화 사용 안 함 → 사용, 요청 시 프로비전 오류 문구, 장치 목록 보류 중, 개요의 장치 동기화 상태
    - 출처: Entra 관리 센터 (2026-11-03~04)
- **조회**: 조인 작업 LastTaskResult 0, AzureAdJoined YES, DomainJoined YES, DeviceAuthStatus SUCCESS
    - 출처: sionnote-cl11 (dsregcmd /status)
- **조회**: 감사 로그 21:48:46 Unregister/Delete → 21:54:59 Restore device(SyncFabric) → 22:01대 Update device(Device Registration Service)
    - 출처: Entra 관리 센터 → 감사 로그, sionnote-cl11 (2026-11-04)

</details>
