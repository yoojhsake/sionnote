---
title: "[IAM] Microsoft Entra ID 핵심 개념: 용어집과 학습 자료"
date: 2026-11-01 08:56:00 +0900
categories: [iam]
tags: [IAM, Entra ID, 용어집, 학습 자료]
excerpt: "PRT·CAE·PIM처럼 낯선 약어를 원어와 쉬운 설명으로 바로 찾는 용어집. 강의와 트러블슈팅 글 목록도 함께 있습니다."
---

PRT, CAE, PIM처럼 Entra ID 글에 나오는 약어가 낯설면 읽다가 멈추게 됩니다. 여기서 원어와 쉬운 한국어 설명을 바로 찾고, 맨 아래 강의와 트러블슈팅 글 목록으로 이어서 공부할 수 있습니다.

## 요약

- 시리즈 용어를 원어와 쉬운 한국어 설명으로 모은 사전임
- 알파벳 순이 아닌 배우는 순서대로 정렬되어 처음부터 훑으면 됨
- 맨 아래 강의와 트러블슈팅 글 목록으로 이어서 공부할 수 있음

> Entra ID 핵심 개념 시리즈: [기초]({{ "/iam/what-is-entra-id/" | relative_url }}) · [오류 코드]({{ "/iam/entra-id-error-codes/" | relative_url }}) · [인증]({{ "/iam/entra-id-authentication/" | relative_url }}) · [접근 제어]({{ "/iam/entra-id-access-control/" | relative_url }}) · [하이브리드·운영]({{ "/iam/entra-id-hybrid-licensing/" | relative_url }}) · **용어집**(지금 글)

---

## 용어집

- **Tenant** · 테넌트: 회사 하나를 위한 독립된 Entra ID 공간. 클라우드의 보안 경계
- **Object** · 개체: 테넌트 안의 사용자·그룹·디바이스·앱·역할
- **Token (ID / Access)** · 토큰(ID 토큰 / 액세스 토큰): 로그인 결과로 받는 전자 출입증. 액세스 토큰은 보통 60~90분 유효
- **PRT (Primary Refresh Token)** · 기본 새로 고침 토큰: 조인된 Windows가 받는 장기 토큰. 앱마다 다시 로그인하지 않게 해 줌
- **Authentication / Authorization** · 인증 / 권한 부여: 누구인지 확인 / 무엇을 할 수 있는지 결정
- **MFA** · 다단계 인증: 서로 다른 종류의 인증 요소 2개 이상
- **Phishing-resistant** · 피싱 저항: 가짜 사이트에 속아도 인증 정보가 넘어가지 않는 성질
- **Passkey (FIDO2)** · 패스키: 등록한 사이트에만 응답하는 공개 키 기반 로그인. 기기 바인딩형·동기화형
- **CBA** · 인증서 기반 인증: 스마트카드·인증서로 로그인
- **AiTM** · 중간자 피싱: 가짜 로그인 페이지를 중간에 두고 코드·세션을 가로채는 공격
- **Security defaults** · 보안 기본값: Free에서 쓰는 기본 보안 스위치(MFA, 레거시 인증 차단 등)
- **Legacy authentication** · 레거시 인증: MFA를 지원하지 않는 옛 인증 방식(IMAP·POP3 기본 인증 등)
- **Device code flow** · 디바이스 코드 흐름: 화면의 코드를 다른 기기에 입력하는 로그인 방식
- **Conditional Access** · 조건부 액세스: If-Then 규칙으로 접근을 허용·요구·차단하는 정책 엔진(P1)
- **Named location** · 명명된 위치: 이름 붙인 IP 범위·국가 조건
- **Authentication strength** · 인증 강도: 허용할 인증 방법의 수준(예: 피싱 저항 MFA만)
- **Compliant device** · 준수 기기: Intune 준수 정책을 통과한 기기
- **Report-only** · 보고서 전용: 차단하지 않고 결과만 기록하는 정책 모드
- **Emergency access (Break-glass)** · 긴급 액세스 계정: 관리자 전원이 잠겼을 때 쓰는 비상 계정
- **Least privilege** · 최소 권한: 필요한 일만 할 수 있는 가장 작은 권한만 주는 원칙
- **Administrative Unit** · 관리 단위: 역할의 관리 범위를 일부 사용자·그룹으로 좁히는 단위(P1)
- **Entra role / Azure RBAC** · Entra 역할 / Azure 역할 기반 액세스 제어: 디렉터리 관리 권한 / 구독·리소스 관리 권한. 서로 별개
- **PIM / Eligible / Active / JIT** · 권한 있는 ID 관리 / 적격 / 활성 / 필요할 때만: 관리자 권한을 시간 제한으로 켜는 방식
- **App registration** · 앱 등록: 앱의 설계도(만든 테넌트에 하나)
- **Enterprise application / Service principal** · 엔터프라이즈 앱 / 서비스 주체: 앱을 쓰는 각 테넌트의 실제 인스턴스
- **Managed identity** · 관리 ID: Azure 리소스에 자동으로 주어지는 자격 증명 없는 ID
- **Consent** · 동의: 앱이 데이터에 접근하도록 사용자·관리자가 허락하는 것
- **SSPR / Writeback** · 셀프 서비스 암호 재설정 / 쓰기 저장: 사용자가 직접 암호 재설정 / 클라우드 변경을 사내 AD에 반영
- **CAE** · 연속 액세스 평가: 계정 사용 안 함 등 중요 이벤트를 몇 분 안에 반영하는 기능
- **PHS / PTA / Federation** · 암호 해시 동기화 / 통과 인증 / 페더레이션: 하이브리드 인증 방식 3가지
- **IdP** · ID 공급자: 인증을 대신 해 주는 시스템(AD FS 등)
- **AD FS / WAP** · AD Federation Services / 웹 애플리케이션 프록시: 사내 페더레이션 서버와 그 외부 공개용 프록시
- **Staging server** · 스테이징 서버: Connect Sync 장애에 대비한 대기 서버
- **CIAM** · 고객 ID·액세스 관리: 고객 가입·로그인 관리(External ID 외부 테넌트)
- **B2B direct connect** · B2B 직접 연결: 게스트 계정 없이 테넌트 간 신뢰로 접근(Teams 공유 채널)
- **SSE / ZTNA / SWG** · 보안 서비스 에지 / 제로 트러스트 네트워크 액세스 / 보안 웹 게이트웨이: Global Secure Access를 이루는 네트워크 보안 개념
- **IaC** · 코드형 인프라: Terraform·Bicep 등 코드로 리소스를 만드는 방식
- **UPN (User Principal Name)** · 사용자 계정 이름: `user@contoso.com` 형식의 로그인 이름
- **Dynamic group** · 동적 그룹: 규칙(예: `user.department -eq "Sales"`)으로 구성원이 자동으로 들어오고 나가는 그룹(P1)
- **Entra registered / joined / hybrid joined** · Entra 등록 / 조인 / 하이브리드 조인: 개인 기기 등록 / 회사 클라우드 기기 / AD 도메인 기기를 클라우드에도 등록
- **Intune**: 기기·앱을 관리하고 준수 여부를 판정하는 Microsoft 서비스
- **TAP (Temporary Access Pass)** · 임시 액세스 패스: 관리자가 발급하는 기간 제한 일회용 코드. 첫 인증 방법 등록에 사용
- **Correlation ID / Request ID** · 상관 관계 ID / 요청 ID: 오류 화면의 "추가 정보"에 나오는 값. 로그인 로그 검색 키
- **HTTP status code** · HTTP 상태 코드: 서버가 요청 결과로 돌려주는 세 자리 숫자. 2xx 성공, 4xx 요청 쪽 문제, 5xx 서비스 쪽 문제
- **401 Unauthorized / 403 Forbidden** · 인증 안 됨 / 권한 없음: 토큰이 없거나 만료됨 / 토큰은 유효하지만 그 작업을 할 권한이 없음
- **429 Too Many Requests / Retry-After** · 요청 과다 / 재시도 대기 시간: 너무 많이 요청해 잠시 막힘(스로틀링). Retry-After에 적힌 초만큼 기다렸다 재시도
- **AADSTS / STS** · Entra 로그인 오류 번호 / 보안 토큰 서비스: 로그인 서버(STS)가 돌려주는 오류 번호. 예: AADSTS50126
- **Authorization_RequestDenied / AuthorizationFailed** · Graph 권한 거부 / Azure 권한 거부: 403과 함께 오는 서비스별 오류 코드
- **Scope** · 스코프(권한 범위) / 범위: Graph에서는 앱이 받은 권한(예: User.Read.All), Azure RBAC에서는 역할이 적용되는 위치(구독·리소스 그룹)
- **What If** · What If 도구: 특정 사용자·조건에서 어떤 조건부 액세스 정책이 걸리는지 미리 보는 도구
- **Protected actions** · 보호된 작업: 조건부 액세스 정책 변경 같은 민감한 작업에 추가 인증을 요구하는 기능
- **Service dependency / Audience** · 서비스 종속성 / 대상 리소스 목록: 앱 하나에 로그인해도 여러 리소스를 함께 요청하는 구조와 그 목록
- **Claims challenge** · 클레임 챌린지: "MFA를 더 하라"처럼 추가 조건을 요구하며 토큰 요청을 되돌리는 응답
- **Seamless SSO** · 원활한 SSO: 사내 도메인 PC에서 클라우드 앱에 자동 로그인하는 하이브리드 기능
- **Cloud Kerberos Trust** · 클라우드 Kerberos 트러스트: Windows Hello for Business를 하이브리드 환경에 배포하는 권장 방식
- **Microsoft Entra Domain Services** · Entra Domain Services: Kerberos·LDAP가 필요한 옛 앱을 위한 Microsoft 관리형 도메인
- **Microsoft-managed policies** · Microsoft 관리형 정책: Microsoft가 테넌트에 만들어 주는 권장 조건부 액세스 정책
- **Access review / Entitlement management / Lifecycle Workflows** · 액세스 검토 / 권한 패키지 / 수명 주기 워크플로: 권한 정기 재확인 / 권한 묶음 신청·승인 / 입사·이동·퇴사 자동화
- **Tier 0** · 티어 0: DC처럼 뚫리면 전체가 위험한 최고 등급 자산. PTA 에이전트·Connect 서버도 이 등급으로 관리
- **디바이스 코드 흐름 / 장치 코드** · 같은 말: 이 블로그의 예전 글은 "장치 코드", 이 글은 공식 화면 용어인 "디바이스 코드 흐름"을 씀

---

M365, Intune, Azure 인프라까지 넓은 용어는 [클라우드 학습 용어 전집]({{ "/study/cloud-study-glossary/" | relative_url }})에 있습니다. 12주 학습 순서는 [Azure·M365 클라우드 학습 로드맵]({{ "/study/cloud-study-roadmap/" | relative_url }})에서 봅니다.

## 함께 보면 좋은 강의

한국어 (Microsoft Learn 학습 모듈)

- [Microsoft Entra ID 소개](https://learn.microsoft.com/ko-kr/training/modules/introduction-to-entra-id-2026/): 강력한 인증, 위험 기반 조건부 액세스, 보안 기본값, 테넌트, 디바이스 ID
- [Microsoft Entra ID에서 인증 방법 관리 및 구현](https://learn.microsoft.com/ko-kr/training/modules/manage-implement-authentication-methods/): MFA, 패스키, 하이브리드 SSPR
- [ID 및 액세스 랩 시작하기](https://learn.microsoft.com/ko-kr/training/modules/get-started-identity-access-labs/): 사용자·그룹, SSPR, MFA, 조건부 액세스 실습

영어 (YouTube, Microsoft 공식 채널)

- [Microsoft Entra ID Beginner's Tutorial (Microsoft Mechanics)](https://www.youtube.com/watch?v=0qZzcK1mHwA): 13분. 관리 센터 화면으로 사용자, 그룹, 역할, 조건부 액세스를 훑는 전체 개요. 2023-10 영상이라 패스키 기본값, SMS 종료, B2C 판매 중단 이전 내용입니다.
- [Why phishing resistant authentication is important](https://www.youtube.com/watch?v=YcqfXvU6xhw): Microsoft Security, 13분, 2024-07. 피싱 저항 인증이 필요한 이유와 패스키, Windows Hello, Authenticator 같은 방식
- [Get started with phishing-resistant MFA](https://www.youtube.com/watch?v=fSIM_Zrlv70): Microsoft Security, 10분, 2024-04. FIDO 인증이 피싱을 막는 원리(채널 바인딩 등)

## 트러블슈팅 글 전체

- 암호가 맞다는데 로그인 실패 → [AADSTS50126: 사용자 이름 또는 암호가 잘못됨]({{ "/iam/troubleshooting/aadsts50126-wrong-password/" | relative_url }})
- MFA 필요·등록 필요, Azure CLI 필수 MFA → [AADSTS50076·50079: MFA가 필요하거나 등록하라고 막힐 때]({{ "/iam/troubleshooting/aadsts50076-mfa-required/" | relative_url }})
- 조건부 액세스 차단 → [AADSTS53003: 조건부 액세스 정책 때문에 차단될 때]({{ "/iam/troubleshooting/aadsts53003-blocked-by-ca/" | relative_url }})
- 로그인은 되는데 권한 없음 → [로그인은 되는데 403·AuthorizationFailed가 나올 때]({{ "/iam/troubleshooting/signed-in-but-403/" | relative_url }})
- 정책 실수로 관리자까지 잠김 → [조건부 액세스 정책 실수로 관리자까지 잠겼을 때: 긴급 액세스 계정]({{ "/iam/troubleshooting/ca-lockout-emergency-access/" | relative_url }})
- 막은 계정이 계속 접근 → [계정을 막았는데 퇴사자가 여전히 메일·파일에 접근할 때]({{ "/iam/troubleshooting/disabled-user-still-signed-in/" | relative_url }})
- 보안 기본값을 켤 수 없음 → [보안 기본값 관리가 보이지 않을 때]({{ "/iam/troubleshooting/security-defaults-cannot-enable/" | relative_url }})
- 셀프 서비스 암호 재설정 실패 → [SSPR이 되지 않을 때: 오류 코드와 쓰기 저장]({{ "/iam/troubleshooting/sspr-cannot-reset/" | relative_url }})
- SMS·음성 MFA 종료 대비 → [SMS·음성으로만 MFA를 하는 사용자가 있을 때]({{ "/iam/troubleshooting/sms-voice-mfa-retirement/" | relative_url }})
- PTA 환경 전원 로그인 실패 → [통과 인증(PTA) 환경에서 전원이 로그인하지 못할 때]({{ "/iam/troubleshooting/pta-agent-sign-in-fails/" | relative_url }})
- 앱에 할당되지 않아 SSO 실패 → [AADSTS50105: 앱에 할당되지 않은 사용자]({{ "/iam/troubleshooting/aadsts50105-app-not-assigned/" | relative_url }})
- 앱 권한 동의 막힘·관리자 승인 필요 → [AADSTS65001·90094: 앱 권한 동의가 막힐 때]({{ "/iam/troubleshooting/aadsts65001-consent-required/" | relative_url }})
- 게스트·외부 계정 로그인 실패 → [AADSTS50020: 게스트가 이 테넌트에 없는 계정으로 막힐 때]({{ "/iam/troubleshooting/aadsts50020-guest-not-in-tenant/" | relative_url }})
- 보안 기본값의 디바이스 코드 차단(실제 사례) → [Exchange Online 장치 코드 로그인이 AADSTS530035로 막힘]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }})
