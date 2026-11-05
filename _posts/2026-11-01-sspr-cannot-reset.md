---
title: "[Troubleshooting] 셀프 서비스 암호 재설정(SSPR)이 되지 않을 때: SSPR 오류 코드와 쓰기 저장"
date: 2026-11-01 09:08:00 +0900
categories: [iam, troubleshooting]
area: 로그인·권한
seq: 8
tags: [Troubleshooting, Entra ID, SSPR, 암호 재설정, 쓰기 저장, writeback, 라이선스, Entra Connect]
excerpt: "SSPR_00xx 코드 번호로 정책, 라이선스, 쓰기 저장 문제를 나누고, 하이브리드는 Entra Connect 이벤트 6800, 32002, 32009를 봅니다."
---

`https://aka.ms/sspr`에서 "지금은 암호를 재설정할 수 없습니다"와 SSPR_00xx 코드가 나왔다면, 코드 번호만으로 정책, 라이선스, 쓰기 저장 중 어디가 문제인지 나눌 수 있습니다. 하이브리드 사용자가 마지막 단계에서 실패하면 Entra Connect 서버 이벤트 6800, 32002, 32009를 확인합니다.

## 요약

- 화면의 SSPR 코드 번호만 보면 어느 설정이 막았는지 나뉨
- 하이브리드가 마지막 단계에서 실패하면 Connect 서버 이벤트 로그를 봄
- SSPR_0009와 SSPR_0011이 갈리는 조건은 이 글에서 시험하지 않았고 문서 표만 인용함

> Microsoft Learn 문서(2026-11-01 확인) 기준입니다. 샌드박스 테넌트에서 SSPR이 꺼진 상태로 사용자 화면을 확인한 결과(2장)를 '2. 원인 및 분석'에 접어 두었습니다.

---

## 전체 내용

### 1. 증상

- 금요일 밤 암호를 잊어 `https://aka.ms/sspr`에 들어간 직원이 본인 확인 전후로 "지금은 암호를 재설정할 수 없습니다"를 받습니다.
- 화면 아래 기술 정보에 **SSPR_00xx** 코드가 보입니다.

### 2. 원인 및 분석

화면 코드 번호로 정책, 라이선스, 쓰기 저장 중 막힌 곳이 나뉩니다([Troubleshoot self-service password reset](https://learn.microsoft.com/entra/identity/authentication/troubleshoot-sspr)).

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/ts-sspr-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/ts-sspr.png" | relative_url }}" alt="SSPR 화면 코드 4가지와 대처" loading="lazy"></picture>

*그림 1. 화면 코드별 원인*

<details markdown="1">
<summary>코드별 의미와 대처 자세히 보기</summary>

- **SSPR_0009** TenantSSPRFlagDisabled
    - 의미: 조직에서 암호 재설정을 **사용하지 않음**
    - 대처: Entra ID > Password reset > Properties에서 SSPR 사용을 **Selected(선택)** 또는 **All(모두)**로
- **SSPR_0010** WritebackNotEnabled
    - 의미: 필요한 **쓰기 저장(writeback)**이 꺼져 있음
    - 대처: 아래 쓰기 저장 확인 참고
- **SSPR_0011** SsprNotEnabledInUserPolicy
    - 의미: 사용자에게 적용되는 재설정 **정책이 정의되지 않음**
    - 대처: 사용자가 SSPR 대상 그룹에 들어 있는지 확인
- **SSPR_0012** UserNotLicensed
    - 의미: 필요한 **라이선스**가 없음
    - 대처: 아래 라이선스 표 확인

</details>

SSPR_0012(라이선스, 문서):

| 작업 | 필요 라이선스 |
|---|---|
| 클라우드 사용자 암호 변경(현재 암호를 앎) | Free 포함 |
| 클라우드 사용자 암호 재설정(잊어버림) | M365 Business Standard 이상 또는 Entra ID P1/P2 |
| 하이브리드 사용자 재설정 + 사내 AD로 쓰기 저장 | M365 Business Premium 또는 Entra ID P1/P2 |

관리 센터에 **Password reset** 메뉴 자체가 안 보이면, 작업하는 관리자 계정에 Entra ID 라이선스가 없는 경우일 수 있습니다(문서).

하이브리드가 마지막 단계에서 실패하면 Password reset > On-premises integration(Entra Connect 구성 시 보임)의 쓰기 저장 Yes 여부와 연결 상태, Connect 서버 응용 프로그램 이벤트 로그의 6800, 32002, 32009를 봅니다. 쓰기 저장은 사내 AD 암호 정책(복잡성, 기록, **최소 사용 기간** 등)을 검사하므로, 어제 암호를 바꾼 사용자의 즉시 거부는 오류가 아니라 **사내 정책대로 동작한 것**입니다.

<details markdown="1">
<summary>쓰기 저장 이벤트별 의미와 대처 보기 (문서)</summary>

- **6800**: 쓰기 저장 엔드포인트가 시작되지 않음
    - 대처: 관련 PasswordResetService 이벤트 확인 → ADSync 서비스 재시작 → 계속되면 쓰기 저장 끄고 다시 켜기
- **32002**: Azure Service Bus에 연결할 수 없음
    - 대처: 방화벽이나 프록시가 아웃바운드 연결을 막는지 확인(연결 필수 조건 문서) 후 서버 재시작
- **32009**: 설치 때 인증 토큰을 받지 못함
    - 대처: 설치에 쓴 하이브리드 관리자 계정 암호가 맞는지, 페더레이션 계정이 아닌지 확인
- **"Multiple matches found"**: 한 사용자가 여러 포리스트에 활성 계정을 가짐
    - 대처: 쓰기 저장에서 지원하지 않는 구성

</details>

사용자가 **인증 방법을 등록**했는지도 봅니다(사용자 > Authentication methods). 2025-09-30부터 인증 방법 정책으로 통합됐고, 보안 질문만 아직 레거시 SSPR 정책에서 관리합니다.

샌드박스에서 확인한 내용: SSPR 범위 "없음" / 기대 코드 SSPR_0009(문서 표의 "꺼짐") / 실제 화면 **SSPR_0011**.

<details markdown="1">
<summary>샌드박스에서 직접 확인한 화면 보기 (그림 2장)</summary>

![암호 재설정 속성 화면. 셀프 서비스 암호 재설정이 사용하도록 설정됨이 없음으로 선택됨]({{ "/assets/images/2026/11/ts-sspr-1-properties.png" | relative_url }})

*그림 2. Entra ID > Password reset > Properties. 이 샌드박스는 "셀프 서비스 암호 재설정이 사용하도록 설정됨"이 "없음"입니다.*

![aka.ms/sspr에서 시험 사용자에게 나온 SSPR_0011 안내 화면]({{ "/assets/images/2026/11/ts-sspr-2-error.png" | relative_url }})

*그림 3. 이 상태에서 시험 사용자가 `aka.ms/sspr`로 들어가자 나온 화면. "조직에서 암호 재설정을 올바르게 설정하지 않아 암호를 재설정할 수 없습니다"와 함께 추가 세부 정보에 **SSPR_0011**(조직에서 암호 재설정 정책을 설정하지 않았습니다)이 보였습니다.*

</details>

### 3. 결론

`SSPR 범위 "없음" → 사용자에게 적용되는 정책 없음 → aka.ms/sspr에서 SSPR_0011`

SSPR_0009와 SSPR_0011이 갈리는 조건은 이 글에서 시험하지 않았습니다. "없음" 상태에서 사용자 화면만 확인했고, SSPR_0009가 나오는 상태를 만들어 비교하지는 않았으므로 문서 표만 인용합니다. 어느 쪽이든 대처는 같으며, 이 시험에서는 설정을 바꾸지 않았습니다.

### 4. 권고방안

1. 조치: SSPR_0009·0011은 Password reset > Properties에서 범위를 Selected나 All로 켜고 대상 그룹 포함 여부 확인, SSPR_0012는 라이선스 할당, SSPR_0010과 쓰기 저장 실패는 이벤트별 대처를 따릅니다.
2. 조치 후 확인: 시험 사용자로 `https://aka.ms/sspr` 재설정을 끝까지 진행하고, 하이브리드는 **사내 AD에서도 새 암호로 로그인**, 감사 로그(사용자 > Audit logs, 서비스 = Self-service Password Management)에 재설정 기록이 있으면 됩니다.
3. 대비: SMS·음성으로만 재설정하던 사용자는 2027년 Microsoft 제공 SMS·음성 종료 일정의 영향을 받습니다([SMS·음성 MFA 종료 대비]({{ "/iam/troubleshooting/sms-voice-mfa-retirement/" | relative_url }})).
4. 지원 요청 시에는 아래 정보(문서)를 모읍니다.

<details markdown="1">
<summary>지원 요청 시 모을 정보 보기 (7항목)</summary>

- 오류 설명과 재현 방법
- 페이지 주소와 캡처
- 화면 아래 **Support code**
- 날짜, 시각과 시간대
- 사용자 ID와 유형(클라우드, PHS, PTA, 페더레이션)
- 라이선스 할당 여부
- 쓰기 저장 문제라면 Entra Connect 서버 응용 프로그램 이벤트 로그

</details>

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (5건)</summary>

- SSPR_0009~0012, 메뉴가 안 보일 때, 지원 요청 정보: [Troubleshoot self-service password reset](https://learn.microsoft.com/entra/identity/authentication/troubleshoot-sspr)
- 쓰기 저장 이벤트 6800, 32002, 32009, 다중 포리스트: [Troubleshoot SSPR writeback](https://learn.microsoft.com/entra/identity/authentication/troubleshoot-sspr-writeback)
- SSPR 라이선스 구분: [Licensing requirements for Microsoft Entra SSPR](https://learn.microsoft.com/entra/identity/authentication/concept-sspr-licensing)
- 쓰기 저장의 사내 정책 검사: [How does SSPR writeback work](https://learn.microsoft.com/entra/identity/authentication/concept-sspr-writeback)
- 레거시 정책 통합, 보안 질문 예외: [Manage authentication methods](https://learn.microsoft.com/entra/identity/authentication/concept-authentication-methods-manage)

</details>
