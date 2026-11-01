---
title: "[Troubleshooting] 통과 인증(PTA) 환경에서 전원이 로그인하지 못할 때 — AADSTS80001·80002"
date: 2026-11-01 09:10:00 +0900
categories: [iam, troubleshooting]
area: 로그인·권한
seq: 10
tags: [Troubleshooting, Entra ID, 하이브리드 ID, PTA, AADSTS80001, AADSTS80002, PHS, 에이전트]
excerpt: "PTA 에이전트나 DC 연결 문제로 클라우드 로그인이 한꺼번에 막힐 때, 80001·80002·80004·80007 코드별 확인과 PHS로의 수동 전환, 에이전트 3대 이상 권장 구성"
---

> Microsoft Learn 공식 문서(2026-11-01 확인)를 기준으로 쓴 대처 가이드입니다. 특정 테넌트에서 재현한 기록은 아닙니다. 개념은 [Entra ID 핵심 개념 — 하이브리드 편]({{ "/iam/entra-id-hybrid-licensing/" | relative_url }})을 함께 보세요. 오류 번호와 HTTP 상태 코드가 낯설면 [오류 코드 읽는 법]({{ "/iam/entra-id-error-codes/" | relative_url }})을 먼저 보세요.

## 요약

- **증상**: PTA를 쓰는 조직에서 동기화된 사용자 전원이 M365 로그인 실패. 클라우드 전용 계정은 로그인됨
- **원인 후보**: PTA 에이전트가 모두 멈춤(80001), 에이전트가 DC에 연결 못 함(80001·80002·80007), 에이전트 서버가 AD "Logon To" 제한에 걸림
- **먼저 볼 곳**: Entra 관리 센터 Microsoft Entra Connect 화면의 PTA 기능 Enabled 여부와 에이전트 Active/Inactive 상태
- **긴급 대처**: 에이전트·DC 복구. 사내 장애가 길어지면 미리 켜 둔 PHS로 수동 전환(자동 전환 안 됨)
- **주의**: 장애 중에 PTA 기능을 끄거나 에이전트를 지우지 않음. 작업은 클라우드 전용 하이브리드 ID 관리자 계정으로

---

## 전체 내용

### 1. 증상

월요일 아침, 사내 서버 점검 이후 동기화된 직원 전원이 Outlook·Teams에 로그인하지 못합니다. 로그인 화면에 AADSTS80001 또는 80002가 보입니다. 반면 `admin@contoso.onmicrosoft.com` 같은 클라우드 전용 관리자 계정은 정상적으로 로그인됩니다.

PTA는 로그인할 때마다 사내 에이전트가 DC에 암호를 확인하는 방식이라, 에이전트나 DC가 응답하지 않으면 클라우드 로그인도 같이 멈춥니다.

### 2. 먼저 확인할 것

1. **클라우드 전용** 하이브리드 ID 관리자 계정으로 Entra 관리 센터에 로그인합니다. 동기화 계정은 같은 이유로 로그인이 안 될 수 있습니다.
2. **Microsoft Entra Connect** 화면에서 Pass-through authentication이 **Enabled**인지, 에이전트 목록이 Active인지 확인합니다.
3. 로그인 로그에서 실패 항목의 **Sign-in error code**를 봅니다.

| 코드(문서) | 의미 | 대처 |
|---|---|---|
| **80001** | 사용할 수 있는 인증 에이전트가 없음 / AD에 연결할 수 없음 | 에이전트 서버·서비스 상태 확인. 에이전트 서버가 사용자와 **같은 포리스트**에 있고 AD에 연결되는지 |
| **80002** | 에이전트의 암호 검증 요청이 시간 초과 | 에이전트에서 AD(DC)에 연결되는지, DC가 응답하는지 |
| 80004 | 잘못된 UPN으로 로그인 요청 | 사용자에게 올바른 사용자 이름 안내 |
| 80005 | 일시적 오류 | 잠시 후 재시도, 계속되면 지원 요청 |
| 80007 | 에이전트가 AD와 통신 중 오류 | 에이전트 로그 확인, AD 상태 확인 |
| 50144 | 사용자의 AD 암호 만료 | 사내 AD에서 암호 재설정 |

### 3. 원인별 대처

- **에이전트 서비스 중지·서버 다운**
    - 확인: 에이전트 서버 상태, 이벤트 뷰어 Applications and Services Logs\Microsoft\AzureAdConnect\AuthenticationAgent\Admin
    - 대처: 서비스 재시작, 서버 복구
- **에이전트 → DC 연결 끊김**
    - 확인: DC 상태, 방화벽
    - 대처: DC 복구, 네트워크 경로 복구
- **에이전트 → 클라우드 아웃바운드 차단**
    - 확인: 443(필수), 80(CRL), 8080(선택) 아웃바운드. `*.msappproxy.net`, `*.servicebus.windows.net` 허용 여부. 아웃바운드 TLS 검사 장비
    - 대처: 방화벽·프록시 예외
- **AD **"Logon To" 제한
    - 확인: 사용자 계정의 로그온 허용 컴퓨터 목록
    - 대처: 에이전트 서버를 "Logon To" 목록에 추가

**에이전트 로그 위치(문서)**: 설치 문제는 `%ProgramData%\AADConnect\trace-*.log`, 로그인 실패 상세는 `%ProgramData%\Microsoft\Azure AD Connect Authentication Agent\Trace\`. 로그의 `Reason` 숫자는 명령 프롬프트에서 `Net helpmsg <번호>`로 뜻을 볼 수 있습니다.

### 4. 사내 장애가 길어질 때 — PHS로 수동 전환

- **PHS를 미리 켜 두었다면** Entra Connect에서 로그인 방식을 PHS로 바꿔 클라우드 로그인을 되살릴 수 있습니다. 자동으로 바뀌지 않으므로 관리자가 직접 전환해야 합니다(문서).
- 전환 절차(문서): Entra Connect 서버에서 Microsoft Entra Connect 구성 마법사 > Configure(구성) > Change user sign-in(사용자 로그인 변경) → 하이브리드 ID 관리자(클라우드 전용 계정 권장) 자격 증명 입력 → **User sign-in**에서 Password Hash Synchronization 선택 → **Enable single sign-on** 페이지(필요 시 도메인 자격 증명) → Ready to configure에서 Configure → 완료 후 Exit.
- 반영 후 클라우드 전용 계정이 아닌 **동기화된 사용자**로 로그인해 확인합니다.
- **Connect 서버 자체가 멈췄다면** 마법사를 실행할 수 없어, PTA를 끄려면 Microsoft 지원이 필요합니다(문서). 그래서 스테이징 서버나 서버 복구 계획을 함께 준비합니다.
- PHS가 꺼져 있었다면 이 선택지가 없습니다. 그래서 문서는 PTA·페더레이션을 쓰더라도 PHS를 **백업으로 함께 켜 두라고** 권장합니다.
- 사내 인프라가 복구되면 계획한 일정에 맞춰 원래 방식으로 되돌릴지 결정합니다.

### 5. 예방

- **에이전트 수**: 운영 환경은 최소 3대(테넌트당 최대 40대). 부하 분산이 아니라 고가용성 목적
- **서버 등급**: 에이전트 서버는 Tier 0(DC급)으로 관리
- **PHS 병행**: 백업 + ID Protection 유출 자격 증명 탐지용
- **스마트 잠금**: Entra 잠금 임계값은 AD보다 작게, 잠금 시간은 AD보다 길게
- **장애 대응 계정**: 클라우드 전용 하이브리드 ID 관리자·긴급 액세스 계정 준비

예시 — 에이전트 3대 중 2대를 같은 날 패치

에이전트가 3대 있어도 같은 시간에 2대를 재부팅하면 남은 1대에 모든 요청이 몰리고, 그 1대마저 문제가 생기면 전원이 로그인하지 못합니다. 패치 일정은 에이전트마다 **다른 시간대**로 나눕니다.

## 근거 자료

- 사용자 화면 오류 80001~80007, 로그인 로그 실패 사유 표, Logon To, 로그 위치, 기능을 끄지 말 것: [Troubleshoot Microsoft Entra pass-through authentication](https://learn.microsoft.com/entra/identity/hybrid/connect/tshoot-connect-pass-through-authentication)
- 에이전트 최소 3대·최대 40대, Tier 0, 포트·URL: [Pass-through authentication: Quickstart](https://learn.microsoft.com/entra/identity/hybrid/connect/how-to-connect-pta-quick-start)
- 로그인 방식 변경(Change user sign-in): [Microsoft Entra Connect user sign-in options](https://learn.microsoft.com/entra/identity/hybrid/connect/plan-connect-user-signin)
- 수동 전환, Connect 서버 장애 시 지원 필요: [Pass-through authentication: Current limitations](https://learn.microsoft.com/entra/identity/hybrid/connect/how-to-connect-pta-current-limitations)
- PHS 백업 권장, 수동 전환: [Choose the right authentication method](https://learn.microsoft.com/entra/identity/hybrid/connect/choose-ad-authn)
- PTA 환경의 스마트 잠금 설정: [Microsoft Entra smart lockout](https://learn.microsoft.com/entra/identity/authentication/howto-password-smart-lockout)
