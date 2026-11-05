---
title: "[Troubleshooting] 통과 인증(PTA) 환경에서 전원이 로그인하지 못할 때: AADSTS80001·80002"
date: 2026-11-01 09:10:00 +0900
categories: [iam, troubleshooting]
area: 로그인·권한
seq: 10
tags: [Troubleshooting, Entra ID, 하이브리드 ID, PTA, AADSTS80001, AADSTS80002, PHS, 에이전트]
excerpt: "PTA 환경에서 동기화 사용자 전원이 로그인 실패할 때, 80001·80002 등 코드별 확인과 미리 켜 둔 PHS로의 수동 전환"
---

PTA를 쓰는 조직에서 동기화된 사용자 전원이 M365에 로그인하지 못하는데, 클라우드 전용 계정만은 들어갑니다. 원인 후보는 PTA 에이전트 정지나 DC 연결 문제입니다. 에이전트와 DC를 복구하되, 사내 장애가 길어지면 미리 켜 둔 PHS로 수동 전환합니다.

## 요약

- 동기화 사용자만 막히면 PTA 에이전트나 DC 연결이 끊긴 것임
- 클라우드 전용 관리자로 에이전트 상태와 로그인 로그 오류 코드부터 확인함
- PHS 전환은 자동이 아니며 PHS를 미리 켜 둔 경우에만 가능함

> Microsoft Learn 문서(2026-11-01 확인) 기준이며, 테넌트에서 재현하지는 않았습니다.

---

## 전체 내용

### 1. 증상

※ 아래 증상은 문서 내용을 바탕으로 가정한 예시이며 실제 테넌트에서 재현한 것이 아닙니다.

- 월요일 아침 사내 서버 점검 이후, 동기화된 직원 전원이 Outlook과 Teams에 로그인하지 못하고 AADSTS80001 또는 80002가 보입니다.
- `admin@contoso.onmicrosoft.com` 같은 클라우드 전용 관리자 계정은 정상 로그인됩니다.

### 2. 원인 및 분석

PTA는 로그인마다 사내 에이전트가 DC에 암호를 확인하므로 에이전트나 DC가 응답하지 않으면 클라우드 로그인도 멈춥니다([Troubleshoot pass-through authentication](https://learn.microsoft.com/entra/identity/hybrid/connect/tshoot-connect-pass-through-authentication)). 어느 지점인지는 로그인 로그의 오류 코드로 가립니다.

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/ts-pta-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/ts-pta.png" | relative_url }}" alt="PTA 로그인 경로와 끊기는 4가지 지점" loading="lazy"></picture>

*그림 1. PTA 경로와 끊기는 지점*

<details markdown="1">
<summary>원인별 확인과 대처, 에이전트 로그 위치 보기 (4가지)</summary>

- **에이전트 서비스 중지, 서버 다운**
    - 확인: 에이전트 서버 상태, 이벤트 뷰어 Applications and Services Logs\Microsoft\AzureAdConnect\AuthenticationAgent\Admin
    - 대처: 서비스 재시작, 서버 복구
- **에이전트 → DC 연결 끊김**
    - 확인: DC 상태, 방화벽
    - 대처: DC 복구, 네트워크 경로 복구
- **에이전트 → 클라우드 아웃바운드 차단**
    - 확인
        - 443(필수), 80(CRL), 8080(선택) 아웃바운드
        - `*.msappproxy.net`, `*.servicebus.windows.net` 허용 여부
        - 아웃바운드 TLS 검사 장비
    - 대처: 방화벽과 프록시 예외
- **AD "Logon To" 제한**
    - 확인: 사용자 계정의 로그온 허용 컴퓨터 목록
    - 대처: 에이전트 서버를 "Logon To" 목록에 추가

**에이전트 로그 위치(문서)**: 설치 문제는 `%ProgramData%\AADConnect\trace-*.log`, 로그인 실패 상세는 `%ProgramData%\Microsoft\Azure AD Connect Authentication Agent\Trace\`. 로그의 `Reason` 숫자는 명령 프롬프트에서 `Net helpmsg <번호>`로 뜻을 볼 수 있습니다.

</details>

<details markdown="1">
<summary>확인 과정 자세히 보기</summary>

1. 클라우드 전용 하이브리드 ID 관리자 계정으로 Entra 관리 센터에 로그인합니다. 동기화 계정은 같은 이유로 로그인이 안 될 수 있습니다.
2. Microsoft Entra Connect 화면에서 Pass-through authentication이 **Enabled**인지, 에이전트 목록이 Active인지 확인합니다.
3. 로그인 로그에서 실패 항목의 **Sign-in error code**를 봅니다.

로그인 로그 코드별 의미와 대처(문서)는 이렇습니다.

- **80001**: 사용할 수 있는 인증 에이전트가 없음 / AD에 연결할 수 없음
    - 대처: 에이전트 서버와 서비스 상태 확인. 에이전트 서버가 사용자와 같은 포리스트에 있고 AD에 연결되는지
- **80002**: 에이전트의 암호 검증 요청이 시간 초과
    - 대처: 에이전트에서 AD(DC)에 연결되는지, DC가 응답하는지
- **80004**: 잘못된 UPN으로 로그인 요청
    - 대처: 사용자에게 올바른 사용자 이름 안내
- **80005**: 일시적 오류
    - 대처: 잠시 후 재시도, 계속되면 지원 요청
- **80007**: 에이전트가 AD와 통신 중 오류
    - 대처: 에이전트 로그 확인, AD 상태 확인
- **50144**: 사용자의 AD 암호 만료
    - 대처: 사내 AD에서 암호 재설정

</details>

### 3. 결론

`점검 후 PTA 에이전트 정지 또는 에이전트→DC 연결 끊김 → 암호 검증 불가(80001·80002) → 동기화 사용자 전원 로그인 실패`

클라우드 전용 계정만 정상인 것이 이 경로의 문제라는 신호입니다. 복구가 늦어질 때의 PHS 전환은 PHS를 미리 켜 둔 경우에만 가능합니다.

### 4. 권고방안

1. 조치: 에이전트(또는 에이전트가 기대는 DC와 네트워크)를 복구합니다. 장애가 길면 **PHS를 미리 켜 두었을 때만** Entra Connect의 Change user sign-in으로 PHS 수동 전환합니다(자동 전환 아님, 문서. 절차는 아래 접힌 블록).
2. 조치 후 확인: 클라우드 전용 계정이 아니라 동기화된 사용자로 로그인되면 해결입니다. 사내 복구 뒤 원래 방식으로 되돌릴지는 계획한 일정에 맞춰 정합니다.
3. 대비: Connect 서버가 멈추면 마법사를 못 써 PTA를 끄려면 Microsoft 지원이 필요하므로(문서) 스테이징 서버나 복구 계획을 둡니다.
4. 예방:
    - **에이전트 수**: 운영 환경은 최소 3대(테넌트당 최대 40대), 고가용성 목적. 패치는 에이전트마다 **다른 시간대**로(2대를 같이 재부팅하면 남은 1대에 몰림)
    - **서버 등급**: 에이전트 서버는 Tier 0(DC급)으로 관리
    - **PHS 병행**: 백업 + ID Protection 유출 자격 증명 탐지용
    - **스마트 잠금**: Entra 잠금 임계값은 AD보다 작게, 잠금 시간은 AD보다 길게
    - **장애 대응 계정**: 클라우드 전용 하이브리드 ID 관리자와 긴급 액세스 계정 준비

<details markdown="1">
<summary>PHS 수동 전환 절차 보기 (5단계, 문서)</summary>

1. Entra Connect 서버에서 Microsoft Entra Connect 구성 마법사 > Configure(구성) > Change user sign-in(사용자 로그인 변경)
2. 하이브리드 ID 관리자(클라우드 전용 계정 권장) 자격 증명 입력
3. **User sign-in**에서 Password Hash Synchronization 선택
4. **Enable single sign-on** 페이지(필요 시 도메인 자격 증명)
5. Ready to configure에서 Configure → 완료 후 Exit

</details>

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (6건)</summary>

- 사용자 화면 오류 80001~80007, 로그인 로그 실패 사유 표, Logon To, 로그 위치, 기능을 끄지 말 것: [Troubleshoot Microsoft Entra pass-through authentication](https://learn.microsoft.com/entra/identity/hybrid/connect/tshoot-connect-pass-through-authentication)
- 에이전트 최소 3대와 최대 40대, Tier 0, 포트와 URL: [Pass-through authentication: Quickstart](https://learn.microsoft.com/entra/identity/hybrid/connect/how-to-connect-pta-quick-start)
- 로그인 방식 변경(Change user sign-in): [Microsoft Entra Connect user sign-in options](https://learn.microsoft.com/entra/identity/hybrid/connect/plan-connect-user-signin)
- 수동 전환, Connect 서버 장애 시 지원 필요: [Pass-through authentication: Current limitations](https://learn.microsoft.com/entra/identity/hybrid/connect/how-to-connect-pta-current-limitations)
- PHS 백업 권장, 수동 전환: [Choose the right authentication method](https://learn.microsoft.com/entra/identity/hybrid/connect/choose-ad-authn)
- PTA 환경의 스마트 잠금 설정: [Microsoft Entra smart lockout](https://learn.microsoft.com/entra/identity/authentication/howto-password-smart-lockout)

</details>
