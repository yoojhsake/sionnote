---
title: "[IAM] Windows 10·11을 Entra ID에 직접 조인하기"
date: 2026-11-04 09:55:00 +0900
categories: [iam]
phase: 하이브리드 실습
seq: 8
tags: [IAM, Entra 조인, AzureAdJoined, PRT, TPM, 도메인 탈퇴]
excerpt: "도메인을 떠난 PC에서 '이 디바이스를 Microsoft Entra ID에 가입'을 눌러 Entra 조인했다. 결과는 AzureAdJoined만 YES이고, 동기화된 사용자로 로그인하면 PRT가 생겼다"
toc: true
---

하이브리드 조인한 두 PC를 도메인에서 떠나게 한 뒤 Entra ID에 직접 조인해 봤습니다. 조인 자체는 한 번의 클릭이고, 확인할 것은 세 가지입니다: `dsregcmd`의 조인 값, TPM 보호 여부, 그리고 어떤 사용자로 로그인했을 때 PRT가 생기는지입니다. 하이브리드 조인과의 값 비교는 [비교 글]({{ "/iam/join-types-comparison/" | relative_url }})에 표로 정리했습니다.

## 요약

- Entra 조인은 AD 도메인에서 먼저 나와야 시작할 수 있었고, 결과는 AzureAdJoined=YES, DomainJoined=NO
- TPM 보호 여부는 VM의 가상 TPM 설정을 그대로 따름(cl10 NO, cl11 YES)
- PRT는 조인 직후 로컬 계정으로는 NO이고, 동기화된 테넌트 사용자로 로그인하면 YES

> 근거 표기: 조회 = 이 랩에서 직접 읽은 값 · 문서 = Microsoft Learn · 확인 불가 = 시도했지만 확인하지 못한 값(방법·사유 병기). 테넌트 ID·도메인·계정 등 비공개 정보는 가리거나 게시하지 않았습니다.

---

## 전체 기록

### 1. 목표

도메인 가입 없이 클라우드에만 등록되는 "Entra 조인" 상태를 만들고, 하이브리드 조인과 다른 점을 `dsregcmd` 값으로 확인합니다.

### 2. 개념

| 조인 방식 | 장치 ID가 있는 곳 | 로그인에 쓰는 계정 | 이 랩의 확인 값 |
|---|---|---|---|
| AD 조인 | 온프레미스 AD만 | AD 계정 | AzureAdJoined NO, DomainJoined YES |
| 하이브리드 조인 | AD와 Entra ID 둘 다 | AD 계정(클라우드 동기화 필요) | AzureAdJoined YES, DomainJoined YES |
| Entra 조인 | Entra ID만 | 테넌트(클라우드) 계정 | AzureAdJoined YES, DomainJoined NO |

### 3. 결과

#### 3-1. 조인 직후 `dsregcmd` 값(조회)

| 항목 | cl10 (Windows 10) | cl11 (Windows 11) |
|---|---|---|
| AzureAdJoined / DomainJoined | YES / NO | YES / NO |
| DeviceAuthStatus | SUCCESS | SUCCESS |
| KeyProvider | Microsoft Software Key Storage Provider | Microsoft Platform Crypto Provider |
| TpmProtected | NO | YES |
| AzureAdPrt(조인 직후 로컬 세션) | NO | NO |

**사용한 명령과 출력** — 각 PC의 명령 프롬프트(조인 직후, 2026-11-04)에서 `dsregcmd /status`의 장치 상태 항목을 읽었습니다. 아래는 화면에서 옮겨 적은 것이고, 장치 ID·테넌트 이름은 적지 않았습니다.

```text
cl10> dsregcmd /status
      AzureAdJoined : YES
   EnterpriseJoined : NO
       DomainJoined : NO
        KeyProvider : Microsoft Software Key Storage Provider
       TpmProtected : NO
   DeviceAuthStatus : SUCCESS
             NgcSet : NO
   WorkplaceJoined  : NO
          AzureAdPrt : NO

cl11> dsregcmd /status
      AzureAdJoined : YES
   EnterpriseJoined : NO
       DomainJoined : NO
        KeyProvider : Microsoft Platform Crypto Provider
       TpmProtected : YES
   DeviceAuthStatus : SUCCESS
             NgcSet : NO
   WorkplaceJoined  : NO
          AzureAdPrt : NO
```

<details markdown="1">
<summary>원본 캡처 보기 (명령 프롬프트 화면, 해상도 낮음)</summary>

![cl10: Entra 조인 직후 dsregcmd]({{ "/assets/images/2026/11/hj-entra-cl10-dsreg.png" | relative_url }})
![cl11: Entra 조인 직후 dsregcmd]({{ "/assets/images/2026/11/hj-entra-cl11-dsreg.png" | relative_url }})

</details>

TPM 보호 여부가 다른 이유는 VM 설정에서 확인됩니다. cl10은 가상 TPM이 꺼져 있고 cl11은 켜져 있어서, 키가 소프트웨어 저장소(cl10)와 플랫폼 암호 공급자(cl11)에 만들어졌습니다(조회: VM 설정 → 보안, 앞 글 참고).

#### 3-2. PRT

동기화된 사용자(`cloudtest01`)로 로그인한 뒤 확인한 값입니다.

| 항목 | 값(조회) |
|---|---|
| AzureAdJoined / DomainJoined | YES / NO |
| AzureAdPrt | **YES** |
| AzureAdPrtUpdateTime | 2026-11-04 01:02:53 UTC |
| AzureAdPrtExpiryTime | 2026-11-18 01:03:14 UTC (약 14일 뒤) |

```text
C:\Users\cloudtest01> dsregcmd /status
      AzureAdJoined : YES
       DomainJoined : NO
         AzureAdPrt : YES
AzureAdPrtUpdateTime : 2026-11-04 01:02:53.000 UTC
AzureAdPrtExpiryTime : 2026-11-18 01:03:14.000 UTC
```

<details markdown="1">
<summary>원본 캡처 보기 (명령 프롬프트 화면, 해상도 낮음)</summary>

![동기화된 사용자 로그인 후 PRT YES]({{ "/assets/images/2026/11/hj-prt-yes-cloudtest01.png" | relative_url }})

</details>

`whoami` 결과가 `sionnote\cloudtest01`로 나옵니다. 장치는 도메인에 가입되어 있지 않은데도 NetBIOS 형태의 이름이 보이는 것은, 이 사용자가 온프레미스 AD에서 동기화되어 온 계정이기 때문으로 보입니다(추정). PRT 갱신 시각이 로그인 직후이고 만료가 2주 뒤인 점은 PRT가 정상 발급되었다는 신호입니다.

### 4. 운영 판단

- **도메인 탈퇴가 먼저**: 문서는 도메인에 가입된 PC를 Entra 조인하려면 먼저 도메인에서 빼라고 안내하고, 하이브리드 조인 PC는 도메인과 Entra ID 양쪽에서 빼라고 안내합니다(문서). cl11은 도메인에 가입된 상태에서 시작해 작업 그룹으로 바꾼 뒤 재시작하고 조인했습니다. cl10은 도메인 가입 전 단계의 체크포인트(`cl10-00`)에서 갈라져 조인했습니다(조회: 체크포인트 트리). 도메인을 떠나면 **AD의 컴퓨터 계정이 비활성**이 될 수 있어서, 하이브리드 상태로 되돌릴 때는 AD 계정 상태도 확인해야 합니다(앞의 AD 구성 글 6절).
- **로그인 계정이 달라지는 점**: Entra 조인 PC는 클라우드 계정으로 로그인하는 것이 기본이고, 하이브리드 조인 PC는 AD 계정으로 로그인합니다. 동기화되지 않은 계정(예: `Admins` OU의 관리용 계정)으로 로그인하면 PRT가 나오지 않습니다(추정, 별도 글에 사례).
- **TPM**: 키를 TPM에 두면 기기 밖으로 복사할 수 없게 되어 토큰 도용에 더 강합니다. 이 랩에서는 cl10에 가상 TPM이 없어서 소프트웨어 키로 조인되었습니다.

### 5. 절차

1. 도메인에 가입된 PC라면(cl11) 시스템 속성 → 컴퓨터 이름 → 변경에서 소속을 **작업 그룹**으로 바꾸고 재시작합니다. 로컬 관리자 암호를 알아야 로그인할 수 있다는 경고가 나옵니다.
2. 설정 → 계정 → 회사 또는 학교 액세스 → **연결**을 누릅니다.
3. "회사 또는 학교 계정 설정" 창 아래쪽의 **이 디바이스를 Microsoft Entra ID에 가입**을 선택합니다(문서).
4. 테넌트 사용자로 로그인하고(직접 입력) 조직 확인 창에서 **가입**을 누릅니다.
5. 완료 후 `dsregcmd /status`로 확인합니다. 동기화된 사용자로 로그인한 뒤 `AzureAdPrt`를 봅니다.

```powershell
dsregcmd /status | Select-String 'AzureAdJoined|DomainJoined|TpmProtected|KeyProvider|AzureAdPrt'
```

### 6. 막힌 곳

- **조인 경로 선택**: 계정 설정 창 위쪽의 이메일 입력칸은 "계정 추가"이고, Entra 조인은 아래쪽 링크를 눌러야 시작됐습니다(조회).
- **PRT가 NO로 나옴**: 조인 직후 로컬 세션에서는 NO였고, 테넌트 사용자로 다시 로그인하자 YES가 됐습니다. 동기화되지 않았거나 Entra에서 사용 안 함인 계정은 PRT가 만들어지지 않습니다(조회: 사용자 사용 안 함 상태에서 AADSTS50057 사례).

### 7. 정리·남은 일

- 두 PC는 이후 하이브리드 조인 상태의 체크포인트로 되돌렸고, 현재 두 PC 모두 하이브리드 조인으로 확인됩니다(조회, 2026-11-04 11:30). AD의 cl11 컴퓨터 계정은 비활성이어서 다시 활성화했습니다.
- 하이브리드 상태로 되돌린 뒤에도 Entra의 장치 목록에는 **Entra 조인 때 만든 장치 레코드가 남아 있습니다**(조회: 모든 디바이스에 `sionnote-cl11`이 "Microsoft Entra 하이브리드"와 "Microsoft Entra 조인" 두 건, `DESKTOP-…` 이름의 Entra 조인 1건). 체크포인트로 PC만 되돌렸을 뿐 클라우드 쪽 레코드는 그대로라서, 같은 이름이 두 번 보입니다. 실습 정리 때는 이 레코드를 삭제합니다(샌드박스 테넌트).
- Entra 조인 화면(회사 또는 학교 계정 설정, 조직 확인)의 캡처는 이번 글에 넣지 못했습니다(확인 불가: 방법 = 당시 캡처 확인, 사유 = 조인 시점 화면 캡처 없음).

<details markdown="1">
<summary>확인 불가 항목 (2건)</summary>

- Entra 조인 마법사 화면 캡처 없음.
- 동기화된 사용자의 `whoami`가 NetBIOS 형태로 나오는 이유: 동작 설명을 문서로 확인하지 않음.

</details>

## 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (5건)</summary>

- (조회) Entra 조인 직후 `dsregcmd /status`: cl10·cl11 PowerShell (2026-11-04 09:xx)
- (조회) PRT 발급 시각·만료: cloudtest01 로그인 후 `dsregcmd /status`
- (조회) VM 가상 TPM 설정: Hyper-V 관리자 → 각 VM 설정 → 보안
- (문서) [Microsoft Entra 조인 장치 개요](https://learn.microsoft.com/entra/identity/devices/concept-directory-join)
- (문서) [장치 배포 계획: 현재 상태별 전환 방법(도메인 가입 → Entra 조인)](https://learn.microsoft.com/entra/identity/devices/plan-device-deployment)

</details>
