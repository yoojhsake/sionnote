---
title: "[IAM] Windows 10·11을 Entra ID에 직접 조인하기"
date: 2026-11-04 16:00:00 +0900
last_modified_at: 2026-11-04 23:59
categories: [iam]
phase: 하이브리드 실습
seq: 8
tags: [IAM, Entra 조인, AzureAdJoined, PRT, TPM, 도메인 탈퇴]
excerpt: "도메인에 가입돼 있지 않은 PC에서 '이 디바이스를 Microsoft Entra ID에 가입'을 눌러 Entra 조인했다. 결과는 AzureAdJoined만 YES이고, 동기화된 사용자로 로그인하면 PRT가 생겼다"
toc: true
---

도메인에 가입돼 있던 PC(cl11)는 작업 그룹으로 바꿔 도메인을 떠나게 한 뒤, 도메인 가입 전 체크포인트에서 시작한 PC(cl10)는 그대로 Entra ID에 직접 조인해 봤습니다. 조인 자체는 한 번의 클릭이고, 확인할 것은 세 가지입니다: `dsregcmd`의 조인 값, TPM 보호 여부, 그리고 어떤 사용자로 로그인했을 때 PRT가 생기는지입니다. 하이브리드 조인과의 값 비교는 [비교 글]({{ "/iam/join-types-comparison/" | relative_url }})에 표로 정리했습니다.

## 요약

- 도메인에 가입된 PC(cl11)는 문서 안내에 따라 AD 도메인에서 먼저 나온 뒤 Entra 조인을 시작했고(문서, 도메인에 가입된 채로는 시도하지 않음. cl10은 도메인 가입 전 체크포인트에서 시작), 결과는 AzureAdJoined=YES, DomainJoined=NO
- 가상 TPM 설정은 cl10이 꺼짐, cl11이 켜짐이었고(조회), TPM 보호 여부도 cl10 NO, cl11 YES였음. 둘의 인과는 추정
- PRT는 조인 직후 로컬 계정으로는 NO이고, 동기화된 테넌트 사용자로 로그인하면 YES

> 근거 표기: 조회 = 이 랩에서 직접 읽은 값 · 문서 = Microsoft Learn · 확인 불가 = 시도했지만 확인하지 못한 값(방법·사유 병기) · 추정 = 조회·문서로 직접 확인하지 못하고 관찰값에서 이어 붙인 해석. 테넌트 ID·테넌트 도메인·클라우드 계정(UPN)은 가렸고, 개인 실습용 도메인(sionnote.local)의 계정 이름·장치 이름·호스트 이름은 그대로 보일 수 있습니다.

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

**사용한 명령과 출력** — 각 PC의 PowerShell(조인 직후, 2026-11-04)에서 `dsregcmd /status`의 장치 상태 항목을 읽었습니다. 아래는 화면에서 옮겨 적은 것이고, 장치 ID·테넌트 이름은 적지 않았습니다.

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

조인 직후 읽은 값과 같은 항목을 같은 PC에서 11-04 20:42에 다시 읽었습니다(조회, 장치 항목만 발췌, 사용자 `cloudtest01` 로그인 상태). 위 표의 cl10 값(KeyProvider·TpmProtected 포함)과 일치합니다.

[![cl10(Windows 10): Entra 조인 상태의 dsregcmd 장치 항목, 소프트웨어 키 저장소·TPM 보호 NO(PowerShell, 글꼴 확대)]({{ "/assets/images/2026/11/en-join-cl10-dsreg-device-hires.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-cl10-dsreg-device-hires.png" | relative_url }}){:target="_blank"}

cl11의 같은 항목은 5-1 ⑬의 캡처에 있습니다(Microsoft Platform Crypto Provider, TpmProtected YES).

VM 설정을 보면 cl10은 가상 TPM이 꺼져 있고 cl11은 켜져 있습니다(조회: VM 설정 → 보안, 앞 글 참고). 키는 cl10에서 소프트웨어 저장소에, cl11에서 플랫폼 암호 공급자에 만들어졌습니다(조회, KeyProvider 값). 이 둘이 같은 원인이라는 해석은 추정입니다. 두 PC가 Windows 10과 11로 달라서 OS 차이도 겹쳐 있고, TPM만 바꿔 다시 조인해 보는 대조는 하지 않았습니다.

#### 3-2. PRT

cl10에서 동기화된 사용자(`cloudtest01`)로 로그인한 뒤 확인한 값입니다(시각은 UTC이며, 갱신 시각은 한국 시간으로 2026-11-04 10:02:53입니다).

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

같은 PC(cl10)에서 11-04 20:41에 다시 읽었습니다(조회). 새로 로그인한 세션이라 `AzureAdPrtUpdateTime`이 20:40(11:40 UTC)로 갱신됐고, 만료 시각은 갱신 시각의 14일 뒤로 표시되어 위 값과 같은 형태입니다. 테넌트 ID는 가렸습니다.

[![cl10에서 cloudtest01로 로그인한 세션: AzureAdPrt YES, 갱신·만료 시각(PowerShell, 글꼴 확대)]({{ "/assets/images/2026/11/hj-prt-yes-cloudtest01-hires.png" | relative_url }})]({{ "/assets/images/2026/11/hj-prt-yes-cloudtest01-hires.png" | relative_url }}){:target="_blank"}

<details markdown="1">
<summary>원본 캡처 보기 (PowerShell 화면, 해상도 낮음)</summary>

[![동기화된 사용자 로그인 후 PRT YES]({{ "/assets/images/2026/11/hj-prt-yes-cloudtest01.png" | relative_url }})]({{ "/assets/images/2026/11/hj-prt-yes-cloudtest01.png" | relative_url }}){:target="_blank"}

</details>

이 캡처에서 읽히는 것은 프롬프트(`C:\Users\cloudtest01>`)와 PRT 항목이고, 로그인 계정 형식(`whoami` 출력)은 이 화면에 없습니다. 그래서 같은 PC(cl10, Entra 조인 상태, cloudtest01로 로그인한 세션)에서 11-04 18:37에 다시 조회했습니다. `whoami`는 `sionnote\cloudtest01`, `whoami /upn`은 클라우드 UPN을 돌려주었습니다(조회, 아래 캡처, 테넌트 부분은 가림). 도메인에 가입되지 않은 장치인데도 NetBIOS 형태의 이름이 나오는 것은 이 사용자가 온프레미스 AD에서 동기화된 계정이기 때문으로 추정합니다(추정: 이 동작을 직접 설명하는 문서는 찾지 못함). `AzureAdPrt`가 YES이고 `AzureAdPrtUpdateTime`이 로그인 직후인 점을 PRT가 발급됐다는 근거로 봅니다(조회). 만료 시각은 근거로 쓰지 않습니다(아래 cl11 설명 참고).

cl11도 같은 방식으로 확인했습니다. 재조인하기 전인 2026-11-04 19:21에 `dsregcmd /status` 전체 출력을 읽었을 때 `AzureAdJoined`가 YES, `DomainJoined`가 NO, `TpmProtected`가 YES, `DeviceAuthStatus`가 SUCCESS, `AzureAdPrt`가 YES(실행 계정 `SIONNOTE\cloudtest02`, 동기화된 사용자), `CloudTgt`가 YES, `OnPremTgt`가 NO였습니다(조회). `AzureAdPrtUpdateTime`은 11-04 07:09 UTC(한국 시간 16:09)였고, `AzureAdPrtExpiryTime`은 14일 뒤로 표시됐습니다. Microsoft Learn의 dsregcmd 문서는 `AzureAdPrtExpiryTime`을 PRT가 갱신되지 않으면 만료되는 시각(UTC), `AzureAdPrtUpdateTime`을 마지막으로 갱신된 시각으로 설명하고(문서: Troubleshoot devices by using the dsregcmd command, SSO state), 기준은 가장 최근에 갱신된 문서(PRT 개념 문서, 2025-07-22 갱신)로 잡았습니다. 이 문서는 PRT가 발급 후 90일 유효하고 사용 중 계속 갱신된다고 설명합니다(문서). 같은 Learn의 'Build resilience with device states' 문서는 14일 유효라고 적고 있는데, 이 문서는 2023-10-23에 마지막으로 갱신된 더 오래된 문서(문서 메타데이터 ms.date 2022-11-16)이고, dsregcmd 문서의 14일 간격 예시(EnterprisePrtUpdateTime 2019-01-24, EnterprisePrtExpiryTime 2019-02-07)는 AD FS Enterprise PRT의 예시 출력이라서 값이 다른 것으로 보입니다(추정: 문서가 서로 다른 시점에 쓰였고 대상이 다르다는 점에서 본 해석이며, 문서에 이 차이를 설명하는 문장은 없습니다). 이 글의 값은 문서가 아니라 제가 읽은 출력입니다. `AzureAdPrtExpiryTime`은 갱신 시각의 14일 뒤로 표시됐고, dsregcmd 문서는 이 필드를 '갱신되지 않으면 만료되는 시각'으로 정의합니다(조회, 문서). 그래서 만료 시각은 정상 발급의 근거로 쓰지 않고, `AzureAdPrt`가 YES라는 값만 근거로 삼습니다. Hello for Business 사전 점검(`PreReqResult`)은 `WillNotProvision`이었는데(조회), 조인과는 별개 항목입니다.

[![cl10(Entra 조인)에서 whoami, whoami /upn, 로컬 Administrators 구성원 조회(PowerShell, whoami /upn 줄은 가림)]({{ "/assets/images/2026/11/en-join-gui-08-whoami-localadmins.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-gui-08-whoami-localadmins.png" | relative_url }}){:target="_blank"}

같은 조회에서 `net localgroup administrators`의 구성원은 `Administrator`, 랩 관리자 계정, 그리고 조인한 사용자 `SIONNOTE\cloudtest01`이었습니다(조회). 문서도 Entra 조인을 수행한 사용자가 로컬 Administrators에 기본으로 들어간다고 안내합니다(문서: 로컬 관리자 그룹 관리).

### 4. 운영 판단

- **도메인 탈퇴가 먼저**: 문서는 도메인에 가입된 PC를 Entra 조인하려면 먼저 도메인에서 빼라고 안내하고, 하이브리드 조인 PC는 도메인과 Entra ID 양쪽에서 빼라고 안내합니다(문서). cl11은 도메인에 가입된 상태에서 시작해 작업 그룹으로 바꾼 뒤 재시작하고 조인했습니다. cl10은 도메인 가입 전 단계의 체크포인트(`cl10-00-clean-net-ready`)에서 갈라져 조인했습니다(조회: 체크포인트 트리). 도메인을 떠나면 **AD의 컴퓨터 계정이 비활성**이 될 수 있어서, 하이브리드 상태로 되돌릴 때는 AD 계정 상태도 확인해야 합니다(앞의 AD 구성 글 6절).
- **로그인 계정이 달라지는 점**: Entra 조인 PC는 클라우드 계정으로 로그인하는 것이 기본이고, 하이브리드 조인 PC는 AD 계정으로 로그인합니다. 동기화되지 않은 계정(예: `Admins` OU의 관리용 계정)으로 로그인하면 PRT가 나오지 않습니다(추정, 별도 글에 사례).
- **TPM**: 키를 TPM에 두면 기기 밖으로 복사할 수 없게 되어 토큰 도용에 더 강합니다(추정: 일반적인 TPM 설명이고 이 랩에서 확인한 것은 아님). 이 랩에서는 cl10에 가상 TPM이 없어서 소프트웨어 키로 조인되었습니다.

### 5. 절차

1. 도메인에 가입된 PC라면(cl11) 시스템 속성 → 컴퓨터 이름 → 변경에서 소속을 **작업 그룹**으로 바꾸고 재시작합니다. 로컬 관리자 암호를 알아야 로그인할 수 있다는 경고가 나옵니다.
2. 설정 → 계정 → 회사 또는 학교 액세스 → **연결**을 누릅니다.
3. "회사 또는 학교 계정 설정" 창 아래쪽의 **이 디바이스를 Microsoft Entra ID에 가입**을 선택합니다(문서).
4. 테넌트 사용자로 로그인하고(직접 입력) 조직 확인 창에서 **가입**을 누릅니다.
5. 완료 후 `dsregcmd /status`로 확인합니다. 동기화된 사용자로 로그인한 뒤 `AzureAdPrt`를 봅니다.

```powershell
dsregcmd /status | Select-String 'AzureAdJoined|DomainJoined|TpmProtected|KeyProvider|AzureAdPrt'
```

#### 5-1. cl11(Windows 11) 기준 조인 절차(GUI, 2026-11-04 재현)

이 절차는 2026-11-04 23:04~23:12에 하이브리드 조인이 끝난 상태의 cl11(도메인 가입, `sionnote\yadmin` 로그인)에서 처음부터 다시 진행하며 찍은 화면입니다. Entra 조인은 도메인에 가입된 PC에서는 할 수 없다고 문서가 안내하므로(문서) 먼저 소속을 작업 그룹으로 바꿨습니다. 테넌트 도메인과 클라우드 계정은 가렸습니다. 로그인(계정·암호 입력)은 사용자가 직접 했고, 캡처는 확대해도 읽히도록 VM 창을 최대화한 상태에서 찍었습니다.

① 시스템 속성(`sysdm.cpl`) → 컴퓨터 이름 탭. 전체 컴퓨터 이름이 `sionnote-cl11.sionnote.local`, 도메인이 `sionnote.local`입니다(조회).

[![시스템 속성: 도메인 sionnote.local에 가입된 상태(GUI)]({{ "/assets/images/2026/11/en-join-cl11-01-sysprops-domain.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-cl11-01-sysprops-domain.png" | relative_url }}){:target="_blank"}

② **변경**을 누르면 "컴퓨터 이름/도메인 변경" 창이 뜨고 소속 그룹이 도메인으로 선택돼 있습니다.

[![컴퓨터 이름/도메인 변경: 소속 그룹이 도메인(GUI)]({{ "/assets/images/2026/11/en-join-cl11-02-change-domain.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-cl11-02-change-domain.png" | relative_url }}){:target="_blank"}

③ **작업 그룹**을 선택하고 이름에 `WORKGROUP`을 입력한 뒤 **확인**을 누릅니다.

[![소속 그룹을 작업 그룹 WORKGROUP으로 변경(GUI)]({{ "/assets/images/2026/11/en-join-cl11-03-change-workgroup.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-cl11-03-change-workgroup.png" | relative_url }}){:target="_blank"}

④ 도메인에서 나간 뒤에는 로컬 관리자 계정의 암호를 알고 있어야 로그인할 수 있다는 경고가 나옵니다. **확인**을 누르면 진행됩니다.

[![도메인에서 나간 뒤 로컬 관리자 암호가 필요하다는 경고(GUI)]({{ "/assets/images/2026/11/en-join-cl11-04-leave-warning.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-cl11-04-leave-warning.png" | relative_url }}){:target="_blank"}

⑤ "WORKGROUP 작업 그룹 시작" 환영 메시지에 이어 "변경 내용을 적용하려면 컴퓨터를 다시 시작해야 합니다"가 나옵니다. 이 과정에서 도메인 관리자 계정을 묻는 창은 나오지 않았습니다(조회).

[![WORKGROUP 작업 그룹 환영 메시지(GUI)]({{ "/assets/images/2026/11/en-join-cl11-05-welcome-workgroup.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-cl11-05-welcome-workgroup.png" | relative_url }}){:target="_blank"}

[![변경 내용을 적용하려면 다시 시작해야 한다는 안내(GUI)]({{ "/assets/images/2026/11/en-join-cl11-06-restart-required.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-cl11-06-restart-required.png" | relative_url }}){:target="_blank"}

⑥ 시스템 속성에는 작업 그룹이 `WORKGROUP`으로 표시되고 "변경 사항은 이 컴퓨터가 다시 부팅된 후에 적용됩니다"라는 안내가 보입니다. **지금 다시 시작**으로 재시작합니다.

[![시스템 속성: 작업 그룹 WORKGROUP, 재부팅 후 적용 안내(GUI)]({{ "/assets/images/2026/11/en-join-cl11-07-sysprops-workgroup.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-cl11-07-sysprops-workgroup.png" | relative_url }}){:target="_blank"}

⑦ 재시작 뒤 로컬 계정(`yadmin`)으로 로그인하고 설정 → 계정 → **회사 또는 학교 액세스**를 엽니다. Windows 11에서는 **연결** 버튼이 오른쪽에 있고 연결된 계정은 아직 없습니다.

[![Windows 11 회사 또는 학교 액세스: 로컬 계정 yadmin, 연결된 계정 없음(GUI)]({{ "/assets/images/2026/11/en-join-cl11-08-access-empty.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-cl11-08-access-empty.png" | relative_url }}){:target="_blank"}

⑧ **연결**을 누르면 "회사 또는 학교 계정 설정" 창이 뜹니다. 위쪽 이메일 입력칸은 "계정 추가(등록)" 경로이고, Entra 조인은 아래쪽의 **이 디바이스를 Microsoft Entra ID에 가입** 링크입니다. 그 아래 링크는 로컬 AD 도메인 가입입니다. 이미 Entra 조인된 PC에서는 같은 창에 이메일 입력칸만 나오고 이 두 링크가 보이지 않았습니다(조회, 2026-11-04 19:24). 설정에서 **연결 끊기**를 누르고 로컬 관리자 계정을 입력한 뒤 다시 시작해 조인을 해제하자 링크가 다시 나타났습니다(조회, 19:28).

[![회사 또는 학교 계정 설정: 이 디바이스를 Microsoft Entra ID에 가입 링크(GUI)]({{ "/assets/images/2026/11/en-join-gui-02-account-setup.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-gui-02-account-setup.png" | relative_url }}){:target="_blank"}

⑨ 링크를 누르면 Microsoft 로그인 화면이 뜹니다. 여기서 테넌트 사용자(Cloud Test02)로 로그인했습니다. 계정과 암호는 사용자가 직접 입력했고, 이 캡처는 입력 전 화면입니다.

[![Microsoft 로그인 화면(GUI)]({{ "/assets/images/2026/11/en-join-gui-03-signin.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-gui-03-signin.png" | relative_url }}){:target="_blank"}

⑩ "조직 확인" 창에 연결 대상(테넌트 도메인), 사용자 이름, 사용자 유형이 나옵니다. 사용자 유형은 **관리자**로 표시됐습니다(조회). **가입**을 누르면 조직 정책이 이 PC에 적용될 수 있다는 안내입니다.

[![조직 확인 창: 연결 대상·사용자 이름(가림)·사용자 유형 관리자, 취소/가입(GUI)]({{ "/assets/images/2026/11/en-join-gui-04-org-confirm.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-gui-04-org-confirm.png" | relative_url }}){:target="_blank"}

⑪ 가입을 누르면 "디바이스를 설정하는 동안 기다려 주세요"가 표시되고(이 대기 화면은 몇 초 만에 지나가서 캡처하지 못했습니다), 잠시 뒤 "모두 설정되었습니다!"가 나옵니다. 이 화면은 이후 이 계정으로 로그인하려면 시작 메뉴에서 계정 전환을 하라고 안내합니다.

[![모두 설정되었습니다: 연결 대상·계정 안내(일부 가림), 완료 버튼(GUI)]({{ "/assets/images/2026/11/en-join-gui-05-all-set.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-gui-05-all-set.png" | relative_url }}){:target="_blank"}

⑫ **완료** 뒤 회사 또는 학교 액세스에 "…에 의해 연결됨 / …의 Entra ID에 연결됨"이 표시됩니다(계정·테넌트는 가림). 항목을 펼치면 **연결 끊기** 버튼만 있고 **정보** 버튼은 없습니다(조회).

[![연결된 직장 계정 항목(이름 가림)(GUI)]({{ "/assets/images/2026/11/en-join-cl11-10-connected.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-cl11-10-connected.png" | relative_url }}){:target="_blank"}

[![항목을 펼친 모습: 연결 끊기 버튼만 있음(GUI)]({{ "/assets/images/2026/11/en-join-cl11-11-connected-expanded.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-cl11-11-connected-expanded.png" | relative_url }}){:target="_blank"}

⑬ 관리자 PowerShell(글꼴 확대)에서 `dsregcmd /status`를 읽은 결과입니다. KeyProvider가 Microsoft Platform Crypto Provider이고 TpmProtected가 YES입니다(조회). TenantName에는 테넌트 이름이 표시됩니다(조회, 값은 가림). 같은 PC가 하이브리드 조인이던 때 TenantName이 빈 값이었던 것과 다른 점입니다([비교 글]({{ "/iam/join-types-comparison/" | relative_url }}) 참고). AzureAdPrt는 NO입니다(조회). 로컬 관리자 세션은 조직 자격 증명으로 Windows에 로그인한 것이 아니라서 PRT가 없는 것으로 봅니다(문서: PRT는 Entra 조인 장치에서 조직 자격 증명으로 로그인할 때 발급됨).

```powershell
dsregcmd /status | Select-String 'AzureAdJoined|DomainJoined|KeyProvider|TpmProtected|DeviceAuthStatus|TenantName|AzureAdPrt '
```

[![dsregcmd: AzureAdJoined YES, DomainJoined NO, TpmProtected YES, DeviceAuthStatus SUCCESS, TenantName 표시(가림), AzureAdPrt NO(글꼴 확대)]({{ "/assets/images/2026/11/en-join-cl11-12-dsreg-hires.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-cl11-12-dsreg-hires.png" | relative_url }}){:target="_blank"}

⑭ Entra 관리 센터 → 디바이스 → 모든 디바이스에 `sionnote-cl11`이 조인 유형 Microsoft Entra 조인, 소유자 Cloud Test02, 등록 11월 4일 오후 11:11로 보입니다(조회). 하이브리드 조인 때의 `sionnote-cl11` 레코드는 목록에 없고, 하이브리드로 남아 있는 것은 `sionnote-cl10`뿐입니다. 같은 목록에 있던 다른 장치 두 대의 이름과 소유자는 가렸습니다.

[![Entra 모든 디바이스: sionnote-cl11이 Entra 조인으로 새로 등록됨(다른 장치 줄은 가림)(GUI)]({{ "/assets/images/2026/11/en-join-cl11-devices-after-rejoin.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-cl11-devices-after-rejoin.png" | relative_url }}){:target="_blank"}

⑮ **감사 로그**(디바이스 → 감사 로그, 범위 지난 1개월)에서 이 재현의 레코드 변화를 시각 순서대로 읽었습니다(조회). 행위자와 대상의 계정 이름은 가렸습니다.

- 오후 11:05:30: **`Unregister device`**와 **`Delete device`**(대상 `sionnote-cl11`). 하이브리드 조인 때의 레코드가 삭제됩니다. `Unregister device`의 행위자는 계정이 아니라 장치 ID인데, 이 ID는 하이브리드 상태였던 cl11의 `dsregcmd` DeviceId와 같습니다(조회, ID 값은 비공개라 글에 적지 않음). 즉 PC가 스스로 등록을 해제한 기록입니다
- 오후 11:11:54~55: cl11이 Cloud Test02로 조인하며 `Add device`, 등록된 소유자·사용자 추가, **`Register device`**가 이어짐

[![Entra 디바이스 감사 로그: 11:05:30 Unregister·Delete device, 11:11:54 Add device·Register device(행위자·대상 계정 가림)(GUI)]({{ "/assets/images/2026/11/en-join-cl11-audit-leave-rejoin.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-cl11-audit-leave-rejoin.png" | relative_url }}){:target="_blank"}

도메인 쪽에서는 ad01 보안 로그에 `SIONNOTE-CL11` 컴퓨터 계정의 비활성화(4725)와 계정 변경(4742)이 오후 11:05:34에 남아 있습니다(조회). Entra의 등록 해제·삭제(11:05:30)가 4초 먼저입니다. 도메인을 떠나는 PC가 먼저 Entra에서 자신을 등록 해제하고, 이어서 AD의 컴퓨터 계정이 비활성화되는 순서입니다.

```powershell
Get-WinEvent -FilterHashtable @{LogName='Security';Id=4725,4742,4741;StartTime=[datetime]'2026-11-04 22:55'} |
  Where-Object { $_.Message -match 'SIONNOTE-CL11' } | Sort-Object TimeCreated | Select-Object TimeCreated,Id | Format-Table -AutoSize
```

[![ad01 보안 로그: 11:05:34 PM 4725, 4742(PowerShell)]({{ "/assets/images/2026/11/en-join-cl11-ad01-events-4725-4742.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-cl11-ad01-events-4725-4742.png" | relative_url }}){:target="_blank"}

이 감사 로그에는 "도메인 탈퇴" 이벤트 자체가 없고, 삭제의 직접 원인이 탈퇴라는 것은 시각 순서와 행위자(장치 자신)에 근거한 판단입니다(추정). 이전 시도(15:18)에서도 같은 순서(Unregister·Delete 후 3초 뒤 4725)가 있었고, 이번에는 체크포인트 없이 하이브리드 조인 상태에서 곧바로 탈퇴해 같은 결과가 나왔습니다(조회).

#### 5-2. cl10(Windows 10) 조인 결과(GUI, 2026-11-04 재현)

cl10은 조인 전 체크포인트(작업 그룹 상태, PC 이름 `DESKTOP-…`)로 되돌려 시작했기 때문에 도메인 탈퇴 단계가 없고, 5-1의 ⑧~⑪과 같은 조인 대화상자를 거쳤습니다. 이 PC에서 로그인한 계정은 Cloud Test01입니다. 화면 구성은 Windows 10과 11이 조금 다르지만 단계는 같습니다.

① 설정 → 계정 → **회사 또는 학교 액세스**. 아직 연결된 계정이 없고 **연결** 버튼만 있습니다.

[![회사 또는 학교 액세스: 연결된 계정 없음, 연결 버튼(GUI)]({{ "/assets/images/2026/11/en-join-gui-01-access-empty.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-gui-01-access-empty.png" | relative_url }}){:target="_blank"}

② **완료**를 누르면 회사 또는 학교 액세스에 "…의 Entra ID에 연결됨"과 연결한 계정이 한 줄로 표시됩니다(이름은 가림). 이 항목을 선택하면 **연결 끊기** 버튼만 있고 하이브리드 조인 때 보이던 **정보** 버튼은 없습니다(조회).

[![회사 또는 학교 액세스: Entra ID에 연결됨(이름 가림)(GUI)]({{ "/assets/images/2026/11/en-join-gui-06-connected.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-gui-06-connected.png" | relative_url }}){:target="_blank"}

③ 관리자 PowerShell(글꼴 확대)에서 `dsregcmd /status`의 항목을 읽었습니다. AzureAdJoined가 YES, DomainJoined가 NO, DeviceAuthStatus가 SUCCESS이고, AzureAdPrt는 NO입니다(조회). 로컬 관리자 세션이라서 그런 것으로 봅니다(문서: PRT는 조직 자격 증명으로 로그인할 때 발급됨).

```powershell
dsregcmd /status | Select-String 'AzureAdJoined|EnterpriseJoined|DomainJoined|DeviceName|DeviceAuthStatus|WorkplaceJoined|AzureAdPrt '
```

[![dsregcmd: AzureAdJoined YES, DomainJoined NO, DeviceAuthStatus SUCCESS, AzureAdPrt NO(글꼴 확대)]({{ "/assets/images/2026/11/en-join-dsreg-01-hires.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-dsreg-01-hires.png" | relative_url }}){:target="_blank"}

④ Entra 관리 센터 → 디바이스 → 모든 디바이스에 조인 직후 새 레코드가 생겼습니다. 이름 `DESKTOP-…`(PC 기본 이름), 조인 유형 Microsoft Entra 조인, 소유자 Cloud Test01, 등록 시각 11월 4일 오후 3:01입니다(조회). 표에서 이름이 가려진 나머지 줄은 이 실습에서 만든 장치가 아니라 같은 테넌트에 이미 있던 다른 장치입니다(이름이 가려져 있어 목록에서 확인했습니다).

[![Entra 모든 디바이스: cl10 Entra 조인 레코드가 새로 생김(GUI)]({{ "/assets/images/2026/11/en-join-gui-06-devices-after-cl10.png" | relative_url }})]({{ "/assets/images/2026/11/en-join-gui-06-devices-after-cl10.png" | relative_url }}){:target="_blank"}

### 6. 막힌 곳

- **조인 경로 선택**: 계정 설정 창 위쪽의 이메일 입력칸은 "계정 추가"이고, Entra 조인은 아래쪽 링크를 눌러야 시작됐습니다(조회).
- **PRT가 NO로 나옴**: 조인 직후 로컬 세션에서는 NO였고, 테넌트 사용자로 다시 로그인하자 YES가 됐습니다(조회). 로컬 계정은 조직 자격 증명으로 로그인한 것이 아니라서 PRT가 없는 것으로 봅니다(문서: PRT 개념 문서의 'How is a PRT issued?'). 별도 사례로, Entra에서 사용 안 함인 계정은 PRT를 받지 못합니다(조회: 하이브리드 조인 PC에서 사용 안 함 상태 계정이 AADSTS50057을 받은 사례, [PRT 글]({{ "/iam/troubleshooting/hybrid-join-prt-no/" | relative_url }}) 참고. 문서: Primary Refresh Token 개념 문서의 'PRT가 무효가 되는 경우').

### 7. 정리·남은 일

- cl11은 2026-11-04 23:04에 하이브리드 조인 상태 그대로 도메인을 떠나(5-1 ①~⑥) 23:11에 Entra 조인했습니다. 그 뒤 23:17 Entra 장치 목록에는 `sionnote-cl11`이 Entra 조인 한 건(소유자 Cloud Test02)이고, 하이브리드로 남아 있는 것은 `sionnote-cl10`입니다(조회). cl10의 5-2는 도메인 가입 전 체크포인트에서 시작한 기록입니다.
- 하이브리드 조인과 PRT 상태는 `cl10-03-hybrid-prt-yes`, `cl11-03-hybrid-prt-yes` 체크포인트에 그대로 있습니다. 하이브리드 실습으로 돌아가려면 그 체크포인트를 적용하고, 지워진 하이브리드 레코드는 체크포인트에 없으므로 Entra 쪽 레코드 상태를 다시 확인해야 합니다(문서: Cloud Sync 경로 기준, Entra ID → 디바이스 → 삭제된 디바이스에서 복원하거나 요청 시 프로비전 사용. 조회: cl11의 하이브리드 레코드는 5-1 ⑮ 감사 로그처럼 도메인 탈퇴 때 삭제됨).
- AD의 컴퓨터 계정 상태는 AD 구성 글 6절에 있습니다. 이번 탈퇴에서도 ad01 보안 로그에 `SIONNOTE-CL11` 컴퓨터 계정의 비활성화(4725)와 변경(4742)이 11:05:34에 남았고(조회), 도메인 탈퇴 때 도메인 관리자 계정을 묻는 창은 나오지 않았습니다(조회, 로그인 계정이 도메인 관리자 `yadmin`). 하이브리드로 돌아갈 때 `Get-ADComputer`로 `Enabled` 값을 먼저 확인하세요.

## 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (13건)</summary>

- (조회) Entra 조인 직후 `dsregcmd /status`: cl10·cl11 PowerShell (2026-11-04 오전)
- (조회) PRT 발급 시각·만료: cloudtest01 로그인 후 `dsregcmd /status`
- (조회) cl10 `whoami`·`whoami /upn`: 2026-11-04 18:37
- (조회) cl11 재조인 전 `dsregcmd /status` 전체 출력: 2026-11-04 19:21
- (조회) cl11 Entra 조인 직후 `dsregcmd /status`(TenantName 표시, TPM 보호 YES, PRT NO): 2026-11-04 23:14
- (조회) VM 가상 TPM 설정: Hyper-V 관리자 → 각 VM 설정 → 보안
- (조회) cl10 재현 조인 과정(2026-11-04 15시대)과 cl11 도메인 탈퇴·Entra 조인 재현(2026-11-04 23:04~23:17): 설정 화면, `dsregcmd`, Entra 관리 센터 디바이스 목록·감사 로그, ad01 보안 로그(4725·4742)
- (문서) [Microsoft Entra 조인 장치 개요](https://learn.microsoft.com/entra/identity/devices/concept-directory-join)
- (문서) [장치 배포 계획: 현재 상태별 전환 방법(도메인 가입 → Entra 조인)](https://learn.microsoft.com/entra/identity/devices/plan-device-deployment)
- (문서) [Understanding Primary Refresh Token (PRT)](https://learn.microsoft.com/entra/identity/devices/concept-primary-refresh-token): 'How is a PRT issued?'에서 Entra 조인 장치는 조직 자격 증명으로 Windows에 로그인할 때 PRT가 발급됨, 'What is the lifetime of a PRT?'에서 발급 후 90일 유효(같은 Learn의 [Build resilience with device states](https://learn.microsoft.com/entra/architecture/resilience-with-device-states)는 2023-10-23 갱신 문서로 14일 유효라고 적어 값이 다름; 이 글은 최신 갱신 문서인 개념 문서를 기준으로 함), 'How is a PRT invalidated?'에서 Entra ID에서 삭제되거나 사용 안 함인 사용자의 PRT는 무효
- (문서) [Configure device sync with Microsoft Entra Cloud Sync](https://learn.microsoft.com/entra/identity/hybrid/cloud-sync/device-sync): Cloud Sync가 아닌 주체가 지운 장치의 복원·요청 시 프로비전 절차
- (문서) [Troubleshoot devices by using the dsregcmd command](https://learn.microsoft.com/entra/identity/devices/troubleshoot-device-dsregcmd#sso-state): SSO state 절의 AzureAdPrtUpdateTime·AzureAdPrtExpiryTime 필드 설명
- (문서) [How to manage the local administrators group on Microsoft Entra joined devices](https://learn.microsoft.com/entra/identity/devices/assign-local-admin): Entra 조인을 수행한 사용자가 로컬 Administrators에 기본으로 추가됨

</details>
