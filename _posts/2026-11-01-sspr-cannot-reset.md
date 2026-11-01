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

- `https://aka.ms/sspr`에서 "지금은 암호를 재설정할 수 없습니다"와 함께 SSPR_00xx 코드, 또는 하이브리드 사용자의 재설정이 마지막 단계에서 실패
- SSPR_0009(조직에서 꺼짐), SSPR_0011(정책 미정의)은 정책 문제. SSPR 사용 범위 설정
- SSPR_0012(라이선스 없음)는 라이선스 문제. 클라우드 사용자 재설정은 Business Standard 이상 또는 P1, 하이브리드 쓰기 저장은 P1 또는 Business Premium
- SSPR_0010(쓰기 저장 미사용)은 Entra Connect나 Cloud Sync에서 쓰기 저장 켜기. 서버 이벤트 6800, 32002, 32009 확인
- 사용자가 인증 방법을 등록하지 않았으면 등록 안내. SMS·음성만 쓰는 사용자는 2027-02-01 Microsoft 제공 SMS·음성 종료(SSPR 포함)에 대비

> Microsoft Learn 공식 문서(2026-11-01 확인)를 기준으로 쓴 대처 가이드입니다. 특정 테넌트에서 재현한 기록은 아닙니다. 개념은 [Entra ID 핵심 개념: 인증 편]({{ "/iam/entra-id-authentication/" | relative_url }})을 함께 보세요. 오류 번호와 HTTP 상태 코드가 낯설면 [오류 코드 읽는 법]({{ "/iam/entra-id-error-codes/" | relative_url }})을 먼저 보세요.

---

## 전체 내용

### 1. 증상

직원이 금요일 밤 암호를 잊어 `https://aka.ms/sspr`에 들어갔지만, 본인 확인 단계 전후로 "지금은 암호를 재설정할 수 없습니다"가 나옵니다. 화면 아래 기술 정보에 **SSPR_00xx** 코드가 보입니다.

### 2. 원인과 해결: 사용자 화면의 코드

- **SSPR_0009** TenantSSPRFlagDisabled
    - 의미: 조직에서 암호 재설정을 **사용하지 않음**
    - 대처: Entra ID > Password reset > Properties에서 SSPR 사용을 **Selected(선택)** 또는 **All(모두)**로
- **SSPR_0010** WritebackNotEnabled
    - 의미: 필요한 **쓰기 저장(writeback)**이 꺼져 있음
    - 대처: 아래 '쓰기 저장이 실패할 때' 참고
- **SSPR_0011** SsprNotEnabledInUserPolicy
    - 의미: 사용자에게 적용되는 재설정 **정책이 정의되지 않음**
    - 대처: 사용자가 SSPR 대상 그룹에 들어 있는지 확인
- **SSPR_0012** UserNotLicensed
    - 의미: 필요한 **라이선스**가 없음
    - 대처: 아래 라이선스 목록 확인

SSPR_0012가 나왔다면 라이선스를 다시 봅니다(문서).

- 클라우드 사용자 암호 변경(현재 암호를 앎): Free 포함
- 클라우드 사용자 암호 재설정(잊어버림): M365 Business Standard 이상 또는 Entra ID P1/P2
- 하이브리드 사용자 재설정 + 사내 AD로 쓰기 저장: M365 Business Premium 또는 Entra ID P1/P2

관리 센터에 **Password reset** 메뉴 자체가 안 보이면, 작업하는 관리자 계정에 Entra ID 라이선스가 없는 경우일 수 있습니다(문서).

#### 하이브리드에서 쓰기 저장이 실패할 때

두 곳을 봅니다. 먼저 Entra 관리 센터 > Password reset > On-premises integration에서 쓰기 저장이 Yes인지와 연결 상태 메시지를 확인합니다. 이 탭은 Entra Connect를 구성해야 보입니다. 그다음 Entra Connect 서버의 응용 프로그램 이벤트 로그에서 아래 이벤트 번호를 찾습니다.

이벤트별 의미와 대처(문서)는 이렇습니다.

- **6800**: 쓰기 저장 엔드포인트가 시작되지 않음
    - 대처: 관련 PasswordResetService 이벤트 확인 → ADSync 서비스 재시작 → 계속되면 쓰기 저장 끄고 다시 켜기
- **32002**: Azure Service Bus에 연결할 수 없음
    - 대처: 방화벽이나 프록시가 아웃바운드 연결을 막는지 확인(연결 필수 조건 문서) 후 서버 재시작
- **32009**: 설치 때 인증 토큰을 받지 못함
    - 대처: 설치에 쓴 하이브리드 관리자 계정 암호가 맞는지, 페더레이션 계정이 아닌지 확인
- **"Multiple matches found"**: 한 사용자가 여러 포리스트에 활성 계정을 가짐
    - 대처: 쓰기 저장에서 지원하지 않는 구성

오류처럼 보이지만 오류가 아닌 경우도 있습니다. 쓰기 저장은 사내 AD 암호 정책(복잡성, 기록, **최소 사용 기간** 등)을 그대로 검사합니다. 어제 암호를 바꾼 사용자가 오늘 다시 재설정하면, 최소 사용 기간 때문에 즉시 거부되고 화면에 바로 안내가 나옵니다. 이 경우 오류가 아니라 **사내 정책대로 동작한 것**입니다.

#### 사용자 쪽 확인

사용자가 재설정에 필요한 **인증 방법을 등록**했는지 확인합니다(사용자 > Authentication methods). 인증 방법 관리는 2025-09-30부터 인증 방법 정책으로 통합됐고, 예외로 보안 질문은 아직 레거시 SSPR 정책에서 관리합니다.

SMS·음성으로만 재설정하던 사용자는 2027년 Microsoft 제공 SMS·음성 종료 일정의 영향을 받습니다([SMS·음성 MFA 종료 대비]({{ "/iam/troubleshooting/sms-voice-mfa-retirement/" | relative_url }})).

### 3. 해결 확인

시험 사용자로 `https://aka.ms/sspr` 재설정을 끝까지 진행하고, 하이브리드라면 **사내 AD에서도 새 암호로 로그인**되는지 확인합니다. 감사 로그(사용자 > Audit logs, 서비스 = Self-service Password Management)에서 재설정 기록도 확인합니다.

### 4. 지원 요청 시 모을 정보(문서)

- 오류 설명과 재현 방법
- 페이지 주소와 캡처
- 화면 아래 **Support code**
- 날짜, 시각과 시간대
- 사용자 ID와 유형(클라우드, PHS, PTA, 페더레이션)
- 라이선스 할당 여부
- 쓰기 저장 문제라면 Entra Connect 서버 응용 프로그램 이벤트 로그

### 5. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (5건)</summary>

- SSPR_0009~0012, 메뉴가 안 보일 때, 지원 요청 정보: [Troubleshoot self-service password reset](https://learn.microsoft.com/entra/identity/authentication/troubleshoot-sspr)
- 쓰기 저장 이벤트 6800, 32002, 32009, 다중 포리스트: [Troubleshoot SSPR writeback](https://learn.microsoft.com/entra/identity/authentication/troubleshoot-sspr-writeback)
- SSPR 라이선스 구분: [Licensing requirements for Microsoft Entra SSPR](https://learn.microsoft.com/entra/identity/authentication/concept-sspr-licensing)
- 쓰기 저장의 사내 정책 검사: [How does SSPR writeback work](https://learn.microsoft.com/entra/identity/authentication/concept-sspr-writeback)
- 레거시 정책 통합, 보안 질문 예외: [Manage authentication methods](https://learn.microsoft.com/entra/identity/authentication/concept-authentication-methods-manage)

</details>
