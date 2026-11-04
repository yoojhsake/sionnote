---
title: "[IAM] AD 조인·하이브리드 조인·Entra 조인 비교 실측"
date: 2026-11-04 16:30:00 +0900
categories: [iam]
phase: 하이브리드 실습
seq: 9
tags: [IAM, AD 조인, 하이브리드 조인, Entra 조인, dsregcmd, PRT, Connect Sync, Cloud Sync]
excerpt: "PC 두 대를 AD 조인, 하이브리드 조인, Entra 조인 상태로 만들어 dsregcmd 값을 비교했다. 조인 방식은 AzureAdJoined와 DomainJoined 조합에서 갈리고, Cloud Test02로 로그인한 뒤 PRT는 하이브리드·Entra 조인 모두 YES였고, 관리자 계정(범위 밖, UPN 접미사 .local)은 NO였다"
toc: true
last_modified_at: 2026-11-05 00:40
---

Windows 10과 Windows 11 PC를 각각 AD 조인, 하이브리드 조인, Entra 조인 상태로 만들어 `dsregcmd /status` 값을 비교했습니다. 세 상태는 AzureAdJoined와 DomainJoined 조합, 그리고 AD 컴퓨터 계정의 필요 여부에서 갈렸고, 하이브리드와 Entra 조인은 동기화된 사용자(Cloud Test02)가 로그인한 뒤 PRT가 발급됐습니다(범위 밖이면서 UPN 접미사가 `.local`인 관리자 계정은 하이브리드에서 NO).

## 요약

- AD 조인은 NO/YES, 하이브리드는 YES/YES, Entra 조인은 YES/NO(AzureAdJoined/DomainJoined)로 갈림
- 하이브리드는 SCP와 동기화가 필요하고, Entra 조인은 인터넷과 Entra 계정만 있으면 됨
- 하이브리드 조인 방식(Connect Sync, Cloud Sync)이 달라도 PC 쪽 결과는 같았음

> 근거 표기: 조회 = 이 랩에서 직접 읽은 값 · 문서 = Microsoft Learn · 추정 = 조회·문서로 직접 확인하지 못하고 관찰값에서 이어 붙인 해석. 테넌트 ID·테넌트 도메인·클라우드 계정(UPN)은 가렸고, 개인 실습용 도메인(sionnote.local)의 계정 이름·장치 이름·호스트 이름은 그대로 보일 수 있습니다.

---

## 전체 기록

### 1. 목표

같은 PC를 조인 방식만 바꿔 가며 어떤 값이 달라지는지 한 표로 정리합니다. 두 PC는 sionnote-cl10(Windows 10 Enterprise 22H2, Connect Sync 경로)과 sionnote-cl11(Windows 11 Enterprise, Cloud Sync 경로)입니다.

### 2. 개념

- **AD 조인**: PC가 AD 도메인에만 등록됨. 로그인은 도메인 계정으로 하고 Entra에는 PC 정보가 없음
- **하이브리드 조인**: AD 도메인 가입을 유지한 채 Entra에도 같은 장치로 등록됨. 컴퓨터 계정이 동기화로 Entra에 올라가야 함
- **Entra 조인**: AD 가입 없이 Entra에만 등록됨. 로그인은 Entra 계정으로 함

### 3. 결과

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/lab-join-types-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/lab-join-types.png" | relative_url }}" alt="AD 조인, 하이브리드 조인, Entra 조인 비교" loading="lazy"></picture>

AzureAdJoined·DomainJoined·DeviceAuthStatus·TenantName·KeyProvider·TpmProtected·AzureAdPrt는 `dsregcmd /status`에서 읽은 값입니다(조회). AD 조인 칸의 AzureAdJoined·DomainJoined·AzureAdPrt는 하이브리드 조인이 끝나기 전 같은 PC에서 읽은 값이고([0x801c03f3 글]({{ "/iam/troubleshooting/hybrid-join-0x801c03f3/" | relative_url }}) 참고), DeviceAuthStatus·TenantName은 이후 하이브리드 조인으로 상태가 바뀐 PC 대신 AD 조인만 된 서버 sionnote-sync01에서 읽었습니다. 사용자 PRT는 같은 글의 캡처에 `AzureAdPrt : NO`로 출력돼 있어 NO로 적었습니다.

| 항목 | AD 조인 | 하이브리드 조인 | Entra 조인 |
|---|---|---|---|
| AzureAdJoined | NO | YES | YES |
| DomainJoined | YES | YES | NO |
| DeviceAuthStatus | 출력 줄 없음(sync01, 아래 캡처) | SUCCESS | SUCCESS |
| TenantName | 출력 줄 없음(sync01, 아래 캡처) | 빈 값(cl10·cl11 모두, 하이브리드 조인 완료 뒤 조회) | 표시됨(캡처, 값은 가림) |
| AD 컴퓨터 계정 | 필요함 | 필요함 | 필요 없음 |
| 사용자 PRT | NO(하이브리드 조인 전 세션의 출력, 0x801c03f3 글의 캡처) | 계정에 따라 다름: Cloud Test02는 로그인 뒤 YES, 관리자 계정 yadmin은 NO([PRT 글]({{ "/iam/troubleshooting/hybrid-join-prt-no/" | relative_url }}) 참고) | 로그인 뒤 YES |

AD 조인만 된 서버에서 같은 항목을 조회하면 AzureAdJoined와 DomainJoined 두 줄만 출력되고 DeviceAuthStatus·TenantName·TenantId 줄은 나오지 않습니다(조회, sionnote-sync01).

```powershell
dsregcmd /status | Select-String 'AzureAdJoined|DomainJoined|DeviceAuthStatus|TenantName|TenantId'
```

[![AD 조인만 된 서버의 dsregcmd 출력: AzureAdJoined NO, DomainJoined YES만 표시]({{ "/assets/images/2026/11/hj-ad-only-sync01-dsreg.png" | relative_url }})]({{ "/assets/images/2026/11/hj-ad-only-sync01-dsreg.png" | relative_url }}){:target="_blank"}

두 상태의 `dsregcmd /status` 값을 같은 PC(cl10)에서 읽어 옮겨 적었습니다(장치 ID·테넌트 값은 생략).

```powershell
dsregcmd /status
```

```text
[1] 하이브리드 조인                      [2] Entra 조인
 AzureAdJoined    : YES                   AzureAdJoined    : YES
 EnterpriseJoined : NO                    EnterpriseJoined : NO
 DomainJoined     : YES                   DomainJoined     : NO
 DomainName       : SIONNOTE              KeyProvider      : Microsoft Software Key Storage Provider
 KeyProvider      : Microsoft Software…   TpmProtected     : NO
 TpmProtected     : NO                    DeviceAuthStatus : SUCCESS
 DeviceAuthStatus : SUCCESS               NgcSet           : NO
 NgcSet           : NO                    WorkplaceJoined  : NO
 WamDefaultSet    : NO                    AzureAdPrt       : NO
 AzureAdPrt       : NO
```

<details markdown="1">
<summary>원본 캡처 보기 (PowerShell 화면, 해상도 낮음)</summary>

[![하이브리드 조인과 Entra 조인의 dsregcmd 값(cl10)]({{ "/assets/images/2026/11/hj-compare-dsreg.png" | relative_url }})]({{ "/assets/images/2026/11/hj-compare-dsreg.png" | relative_url }}){:target="_blank"}

</details>

두 PC의 키 보호 방식은 달랐습니다. VM의 가상 TPM 설정은 cl10이 꺼짐, cl11이 켜짐이었습니다(조회). 이 설정 차이가 키 보호 방식의 차이를 만들었다고 보지만, Windows 10과 11이라는 차이도 겹쳐 있어 원인은 추정입니다([환경 글]({{ "/iam/hyperv-lab-environment/" | relative_url }}) 참고).

| 항목 | Windows 10 PC | Windows 11 PC |
|---|---|---|
| KeyProvider | 소프트웨어 키 | Platform Crypto Provider |
| TpmProtected | NO | YES |

#### 설정 화면(GUI)에서 보이는 차이

같은 Windows 10 PC(cl10)의 설정 → 계정 → **회사 또는 학교 액세스** 화면입니다(조회, 2026-11-04). 조인 방식에 따라 보이는 항목이 다릅니다.

하이브리드 조인 상태에서는 "SIONNOTE AD 도메인에 연결됨(`sionnote.local`)" 한 줄만 보입니다. 도메인 쪽 연결만 표시되고 Entra 쪽 등록 여부는 이 화면에서 알 수 없습니다.

[![하이브리드 조인 상태(cl10): SIONNOTE AD 도메인에 연결됨(GUI)]({{ "/assets/images/2026/11/hj-cl10-gui-01-work-school.png" | relative_url }})]({{ "/assets/images/2026/11/hj-cl10-gui-01-work-school.png" | relative_url }}){:target="_blank"}

Entra 조인 상태에서는 "…의 Entra ID에 연결됨"과 연결한 계정이 표시되고, 항목을 선택하면 **연결 끊기** 버튼만 있습니다(조회, 테넌트와 계정은 가림).

[![Entra 조인 상태(cl10): Entra ID에 연결됨(GUI)]({{ "/assets/images/2026/11/en-join-gui-06-connected.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-gui-06-connected.png" | relative_url }}){:target="_blank"}

조인 전(작업 그룹) 상태에서는 연결된 항목이 없고 **연결** 버튼만 있습니다.

[![조인 전 상태(cl10): 연결된 계정 없음(GUI)]({{ "/assets/images/2026/11/en-join-gui-01-access-empty.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-gui-01-access-empty.png" | relative_url }}){:target="_blank"}

### 4. 운영 판단

- 하이브리드 조인은 SCP와 장치 동기화를 모두 갖춰야 합니다. PC가 한 번 시도해 인증서를 AD에 기록하면(이때 첫 시도는 0x801c03f3으로 실패) 동기화가 그 계정을 올리고, 그 뒤 재시도에서 성공합니다.
- 하이브리드의 PRT는 Entra에 사용자가 있어야 하며, 사용자가 없으면 AADSTS50034로 실패한다고 문서가 안내합니다(문서: Troubleshoot Microsoft Entra hybrid joined devices). 이 랩에서 범위 밖 OU의 관리자 계정(yadmin)은 PRT가 NO였지만 직접 원인은 UPN 접미사 `.local`(AADSTS90002)이었고, 사용자 부재(AADSTS50034)는 관측하지 못했습니다(조회, cl10 2026-11-05 00:01 로그온 1건, 아래 PRT 글 참고).
- Entra 조인은 도메인 가입 PC에서는 먼저 도메인에서 빼야 한다고 문서가 안내합니다(문서). 이 랩은 문서 안내에 따라 Windows 11 PC를 작업 그룹으로 바꾼 뒤 Entra 조인했고(도메인에 가입된 채로 조인해 보는 시도는 하지 않았습니다), Windows 10 PC는 도메인 가입 전 체크포인트에서 갈라져 조인했습니다.
- 사용자 유형이 "관리자"로 표시되는 "조직 확인" 창이 Entra 조인 중에 나왔습니다. 이 표시의 의미를 직접 설명하는 문서는 찾지 못했습니다(시도: Learn 검색 2회). 대신 조인을 마친 cl10에서 `net localgroup administrators`를 조회하니 조인한 사용자가 로컬 Administrators에 들어 있었고(조회, 2026-11-04 18:37), 문서도 같은 동작을 안내합니다(문서: 로컬 관리자 그룹 관리). 그래서 "관리자" 표시는 이 로컬 관리자 권한을 뜻하는 것으로 보입니다(추정).

### 5. 절차

#### AD 조인 (GUI)

1. PC에서 시스템 속성 → 컴퓨터 이름 → 변경에서 컴퓨터 이름을 정하고 소속을 **도메인**으로 선택해 도메인 이름을 입력합니다.
2. 도메인 가입 권한이 있는 계정의 자격 증명을 입력하고(직접 입력) 재시작합니다.
3. `dsregcmd /status`에서 DomainJoined가 YES인지 확인합니다.

#### 하이브리드 조인

방식별 구성은 [Connect Sync 글]({{ "/iam/hybrid-join-connect-sync/" | relative_url }})과 [Cloud Sync 글]({{ "/iam/hybrid-join-cloud-sync/" | relative_url }})을 참고합니다. PC 쪽 작업은 둘 다 같습니다.

```powershell
$p = '\Microsoft\Windows\Workplace Join\'
Start-ScheduledTask -TaskPath $p -TaskName 'Automatic-Device-Join'
Start-Sleep 40
dsregcmd /status | Select-String 'AzureAdJoined|DomainJoined|DeviceAuthStatus|AzureAdPrt '
```

#### Entra 조인 (GUI)

화면별 값과 PRT 확인은 [Entra 조인 글]({{ "/iam/entra-join-cl10-cl11/" | relative_url }})에 따로 정리했습니다.

1. 도메인 가입 상태라면 시스템 속성 → 컴퓨터 이름 → 변경에서 소속을 **작업 그룹**으로 바꾸고 재시작합니다. 로컬 관리자 암호를 알아야 로그인할 수 있다는 경고가 나옵니다.
2. 설정 → 계정 → 회사 또는 학교 액세스 → **연결**을 누릅니다.
3. "회사 또는 학교 계정 설정" 창 아래쪽의 **이 디바이스를 Microsoft Entra ID에 가입**을 선택합니다.
4. 테넌트 사용자로 로그인하고(직접 입력) 조직 확인 창에서 **가입**을 누릅니다.
5. 완료 화면에서 **완료**를 누르고 `dsregcmd /status`로 확인합니다.

### 6. 막힌 곳

- **조인 경로 선택**: "회사 또는 학교 계정 설정" 창은 위쪽에 이메일 입력칸이 있고, Entra 조인은 아래쪽 "이 디바이스를 Microsoft Entra ID에 가입" 링크를 눌러야 시작됐습니다(조회).
- **PRT**: Entra 조인 직후 로컬 계정 세션에서는 PRT가 NO입니다. 테넌트 사용자로 로그인한 뒤에 YES가 됐습니다(조회).

### 7. 정리·남은 일

- AD 조인 칸은 조인 전 상태의 값입니다. 비교는 PC 두 대에서 한 번씩만 확인한 결과입니다.
- 하이브리드 조인 레코드가 Entra에 남아 있던 PC(cl10)를 다시 도메인에 가입시켰을 때 조인이 0x801c005b(error_computer_signature_check_failure)로 실패한 사례가 한 건 있습니다(조회, 이 한 건만 확인). 사례와 해결은 [Connect Sync 글]({{ "/iam/hybrid-join-connect-sync/" | relative_url }})에 정리했습니다.
- 하이브리드 조인 쪽 PRT 실패 원인은 [하이브리드 조인 후 AzureAdPrt가 NO일 때]({{ "/iam/troubleshooting/hybrid-join-prt-no/" | relative_url }})에 정리했습니다.

## 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (6건)</summary>

- **조회**: 세 상태의 dsregcmd 값(AzureAdJoined, DomainJoined, DeviceAuthStatus, TenantName, KeyProvider, TpmProtected, AzureAdPrt)
    - 출처: sionnote-cl10, sionnote-cl11 (2026-11-03~04)
- **조회**: AD 조인만 된 서버의 dsregcmd 출력(AzureAdJoined NO, DomainJoined YES 두 줄만 출력)
    - 출처: sionnote-sync01 (2026-11-04 23:00)
- **조회**: 하이브리드 조인 PC의 PRT(Cloud Test02 YES, yadmin NO)와 TenantName 빈 값
    - 출처: sionnote-cl10, sionnote-cl11 (2026-11-04)
- **문서**: 하이브리드 조인 확인 방법(장치 목록의 등록됨 열이 보류 중이면 조인 미완료, 날짜면 완료)
    - 출처: [Verify Microsoft Entra hybrid join](https://learn.microsoft.com/entra/identity/devices/how-to-hybrid-join-verify)
- **문서**: dsregcmd 진단 데이터(조인 단계와 오류 코드)
    - 출처: [Troubleshoot devices by using the dsregcmd command](https://learn.microsoft.com/entra/identity/devices/troubleshoot-device-dsregcmd)
- **문서**: Entra 조인을 수행한 사용자는 기본으로 로컬 Administrators 그룹에 추가됨
    - 출처: [How to manage the local administrators group on Microsoft Entra joined devices](https://learn.microsoft.com/entra/identity/devices/assign-local-admin)

</details>
