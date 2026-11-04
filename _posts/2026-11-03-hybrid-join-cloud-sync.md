---
title: "[IAM] Cloud Sync로 하이브리드 조인 구성하기"
date: 2026-11-03 17:00:00 +0900
categories: [iam]
phase: 하이브리드 실습
seq: 7
tags: [IAM, 하이브리드 조인, Entra Cloud Sync, 장치 동기화, 요청 시 프로비전, Windows 11]
excerpt: "Cloud Sync는 포털에서 디바이스 동기화를 켜는 것만으로 컴퓨터 계정을 Entra에 올린다. 요청 시 프로비전의 오류 문구와 달리 장치는 보류 중으로 생성됐고, 재시도에서 조인이 끝났다"
toc: true
---

Cloud Sync 쪽 PC(Windows 11)를 하이브리드 조인하려고 포털에서 디바이스 동기화를 켰습니다. 서버에 마법사를 돌리지 않고 구성 속성의 체크박스 하나와 요청 시 프로비전으로 장치를 Entra에 올렸고, PC에서 조인 작업을 다시 실행하자 AzureAdJoined와 DomainJoined가 모두 YES가 됐습니다.

## 요약

- Cloud Sync의 장치 동기화는 기본이 꺼져 있고, 구성 속성에서 체크박스를 켜면 됨
- 요청 시 프로비전 화면에 오류 문구가 떠도 장치 목록에 "보류 중"으로 생기면 성공함
- SCP는 포리스트에 하나만 있으면 되어서 Connect Sync 쪽에서 만든 것을 그대로 씀

> 근거 표기: 조회 = 이 랩에서 직접 읽은 값 · 문서 = Microsoft Learn · 확인 불가 = 시도했지만 확인하지 못한 값(방법·사유 병기). 테넌트 ID·도메인·계정 등 비공개 정보는 가리거나 게시하지 않았습니다.

---

## 전체 기록

### 1. 목표

OU=CloudSync에 있는 Windows 11 Enterprise PC(sionnote-cl11)를 Cloud Sync 경로로 하이브리드 조인합니다. [Connect Sync 글]({{ "/iam/hybrid-join-connect-sync/" | relative_url }})과 같은 서버에서 비교하는 두 번째 글입니다.

### 2. 개념

Cloud Sync는 동기화 구성과 실행 계획이 포털(클라우드)에 있고, 서버에는 가벼운 프로비저닝 에이전트만 설치합니다(문서). 컴퓨터 계정을 올리는 일은 AD to Microsoft Entra ID 구성 안의 장치 동기화(AD2AADDeviceSync 작업)가 맡습니다(문서).

- **디바이스 동기화**: 기본은 사용 안 함이고, 켜면 범위 안의 컴퓨터 계정을 Entra로 보냄
- **요청 시 프로비전**: 사용자나 장치 한 개를 지금 바로 동기화해 보는 포털 기능
- **SCP**: Connect Sync와 같은 포리스트 단위 객체라서 방식과 상관없이 한 번만 만들면 됨

### 3. 결과

| 항목 | 값 |
|---|---|
| 디바이스 동기화(포털 속성) | 사용 안 함 → 사용 |
| 장치 목록의 등록됨 열 | 보류 중 → 조인 후 날짜 |
| AzureAdJoined / DomainJoined | YES / YES |
| DeviceAuthStatus | SUCCESS |

**GUI로 본 PC 쪽 상태**: 설정 → 계정 → **회사 또는 학교 액세스**에는 `sionnote.local`, "SIONNOTE AD 도메인에 연결됨"이 보입니다(조회, 2026-11-04). 도메인 연결만 보이고 Entra 등록 여부는 이 화면에 나오지 않아서 `dsregcmd`와 Entra 포털의 장치 목록으로 확인합니다.

![cl11 설정 > 회사 또는 학교 액세스(GUI)]({{ "/assets/images/2026/11/hj-cl11-gui-01-work-school.png" | relative_url }})

조인 예약 작업은 **작업 스케줄러**(`taskschd.msc`) → 작업 스케줄러 라이브러리 → Microsoft → Windows → **Workplace Join**의 `Automatic-Device-Join`입니다. 상태 "준비", 마지막 실행 2026-11-04 오후 1:19:25, 결과 "작업을 완료했습니다(0x0)"입니다(조회).

![cl11 작업 스케줄러: Workplace Join > Automatic-Device-Join(GUI)]({{ "/assets/images/2026/11/hj-cl11-gui-02-task-scheduler.png" | relative_url }})

`dsregcmd /status`는 PowerShell로만 볼 수 있습니다. 글꼴을 키워 다시 찍은 화면입니다(cl11, `sionnote\yadmin`, 2026-11-04, 장치 ID·테넌트 값 제외). cl11은 가상 TPM이 켜져 있어 KeyProvider가 Platform Crypto Provider, TpmProtected가 YES입니다.

```powershell
whoami
dsregcmd /status | Select-String 'AzureAdJoined|EnterpriseJoined|DomainJoined|DomainName|KeyProvider|TpmProtected|DeviceAuthStatus|NgcSet|AzureAdPrt '
```

![cl11 dsregcmd 결과(글꼴 확대, 2026-11-04)]({{ "/assets/images/2026/11/hj-cl11-dsreg-hybrid-hires.png" | relative_url }})

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

![하이브리드 조인 후 dsregcmd 결과(Cloud Sync 경로)]({{ "/assets/images/2026/11/hj-cl11-dsreg-hybrid.png" | relative_url }})

</details>

#### 3-2. 포털 구성 확인(2026-11-04 조회)

| 화면 | 확인한 값 |
|---|---|
| 구성 개요 | 암호 해시 동기화 사용, **디바이스 동기화 사용**, Exchange 하이브리드 쓰기 저장 사용 안 함, 에이전트 1 사용, 장치 동기화 상태 컴퓨터 1건 100% 완료 |
| 속성 > 기본 | 실수로 인한 삭제 방지 사용, 삭제 임계값 500 |
| 필터 범위 지정 | **선택한 조직 구성 단위 동기화**: `OU=CloudSync,OU=CloudSyncLab,DC=sionnote,DC=local` 하나 |
| 에이전트 | `sionnote-sync01.sionnote.local` 활성(외부 IP는 가림) |

![구성 개요: 디바이스 동기화 사용, 에이전트 1, 컴퓨터 1건 동기화]({{ "/assets/images/2026/11/cs-portal-01-overview.png" | relative_url }})
![필터 범위 지정: OU=CloudSync만 선택]({{ "/assets/images/2026/11/cs-portal-02-scope.png" | relative_url }})
![에이전트: sync01 활성]({{ "/assets/images/2026/11/cs-portal-03-agents.png" | relative_url }})

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
5. **Entra ID → 장치 → 모든 디바이스**에서 PC가 "보류 중"으로 보이는지 확인합니다(조인이 끝난 지금은 등록 날짜가 표시됩니다).
6. PC에서 Automatic-Device-Join을 다시 실행하고 `dsregcmd /status`로 확인합니다.

![속성 > 기본: 디바이스 동기화 "사용"(현재 상태)]({{ "/assets/images/2026/11/hj-cloud-02-enable.png" | relative_url }})

![요청 시 프로비전 > 디바이스 탭: 컴퓨터의 고유 이름(DN)을 입력하는 칸]({{ "/assets/images/2026/11/hj-cloud-03-ondemand.png" | relative_url }})

![모든 디바이스(현재 상태): cl10·cl11이 Microsoft Entra 하이브리드 조인으로 표시]({{ "/assets/images/2026/11/hj-cloud-04-devices.png" | relative_url }})

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
- **개요 화면의 장치 상태**: 디바이스 동기화를 켠 직후에는 "초기 동기화가 실행되지 않음"으로 보였고, 얼마 뒤 컴퓨터 1건이 100% 완료로 바뀌었습니다(조회).

### 7. 정리·남은 일

- 장치 동기화 작업의 정기 실행 주기는 이번에 확인하지 못했습니다. 일상 운영에서는 이 주기를 알아야 조인 지연을 예측할 수 있습니다.
- 사용자 PRT까지 확인한 결과는 [하이브리드 조인 후 AzureAdPrt가 NO일 때]({{ "/iam/troubleshooting/hybrid-join-prt-no/" | relative_url }})에 정리했습니다.

### 8. 확인 불가

<details markdown="1">
<summary>확인 불가 펼쳐 보기 (2건)</summary>

- **요청 시 프로비전 오류 문구의 의미**: 같은 호출을 두 번 반복하고 장치 목록과 비교했지만 문구는 그대로였고 장치는 생성됐습니다. 서비스 쪽 로그를 볼 수 없어서 이유는 알 수 없습니다.
- **장치 동기화의 정기 주기**: 개요 화면에서는 초기 동기화 상태만 보였고 정기 주기는 표시되지 않았습니다.

</details>

## 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (4건)</summary>

- **문서**: 디바이스 동기화 구성(에이전트 1.1.1107 이상, 하이브리드 ID 관리자 이상, 요청 시 프로비전 절차)
    - 출처: [Configure device sync with Microsoft Entra Cloud Sync](https://learn.microsoft.com/entra/identity/hybrid/cloud-sync/device-sync)
- **문서**: Cloud Sync가 컴퓨터 계정을 동기화해 하이브리드 조인이 가능하다는 설명
    - 출처: [What is Microsoft Entra Cloud Sync?](https://learn.microsoft.com/entra/identity/hybrid/cloud-sync/what-is-cloud-sync)
- **조회**: 속성 > 기본의 디바이스 동기화 사용 안 함 → 사용, 요청 시 프로비전 오류 문구, 장치 목록 보류 중, 개요의 장치 동기화 상태
    - 출처: Entra 관리 센터 (2026-11-03~04)
- **조회**: 조인 작업 LastTaskResult 0, AzureAdJoined YES, DomainJoined YES, DeviceAuthStatus SUCCESS
    - 출처: sionnote-cl11 (dsregcmd /status)

</details>
