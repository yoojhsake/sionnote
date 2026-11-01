---
title: "[IAM] Microsoft Entra ID 핵심 개념: 오류 코드 읽는 법(HTTP 상태 코드와 AADSTS)"
date: 2026-11-01 08:59:30 +0900
categories: [iam]
tags: [IAM, Entra ID, HTTP 상태 코드, "401", "403", "429", AADSTS, Microsoft Graph, AuthorizationFailed, 오류 코드]
excerpt: "401은 토큰이 없거나 만료, 403은 권한 없음. 상태 코드와 AADSTS 번호로 로그인 단계와 호출 단계를 가르는 법"
---

오류 화면에 401이 뜨면 출입증(토큰)이, 403이 뜨면 그 방에 들어갈 권한이 문제입니다. 이 글을 읽고 나면 HTTP 상태 코드와 AADSTS 번호만 보고 오류가 로그인 단계에서 났는지 호출 단계에서 났는지 먼저 가를 수 있습니다.

## 요약

- 401은 출입증(토큰)이 없거나 만료됨, 403은 출입증은 유효한데 그 방에 들어갈 권한이 없음
- 오류는 보통 세 겹: HTTP 상태 코드(큰 분류, 예: 403), 서비스 오류 코드(예: AADSTS50126, Authorization_RequestDenied), 사람이 읽는 메시지
- 4로 시작하면 요청하는 쪽(사용자, 앱, 설정) 문제, 5로 시작하면 서비스 쪽 문제일 가능성이 큼
- AADSTS로 시작하는 번호는 로그인 단계(Entra ID) 오류. 로그인 로그에서 같은 번호로 찾음
- 대처는 단계 나누기부터. 로그인 단계면 로그인 로그, 호출 단계면 토큰과 권한

근거: Microsoft Learn 공식 문서(2026-11-01 확인). HTTP 상태 코드의 일반 의미는 웹 표준 내용이고, Entra, Graph, Azure에서의 의미는 문서로 확인했습니다. 낯선 용어는 [용어집]({{ "/iam/entra-id-glossary/" | relative_url }})을 함께 보세요.

> **시리즈: Microsoft Entra ID 핵심 개념**
>
> 1. [기초와 구조]({{ "/iam/what-is-entra-id/" | relative_url }})
> 2. **오류 코드 읽는 법(HTTP 상태 코드와 AADSTS)** (지금 보는 글)
> 3. [인증(MFA, 패스키, SSPR, SSO)]({{ "/iam/entra-id-authentication/" | relative_url }})
> 4. [접근 제어(조건부 액세스, PIM, ID Protection)]({{ "/iam/entra-id-access-control/" | relative_url }})
> 5. [하이브리드, 외부 사용자, 라이선스, 운영]({{ "/iam/entra-id-hybrid-licensing/" | relative_url }})
> 6. [용어집과 학습 자료]({{ "/iam/entra-id-glossary/" | relative_url }})

---

## 전체 내용

### 1. HTTP 상태 코드란

브라우저나 스크립트가 서버에 무언가를 요청하면, 서버는 결과와 함께 세 자리 숫자를 돌려줍니다. 이것이 **HTTP 상태 코드(HTTP status code)**입니다. 식당 주문에 비유하면, 음식(결과)과 함께 "주문 완료", "메뉴에 없음", "주방 고장" 같은 짧은 답을 주는 것입니다.

첫 자리로 다섯 묶음이 나뉩니다.

- 1xx 정보: 처리 중. 평소에는 거의 볼 일이 없습니다.
- 2xx 성공: 요청이 처리됐습니다.
- 3xx 리디렉션: 다른 주소로 가라는 안내입니다. 앱에 접속했을 때 Entra 로그인 화면으로 넘어가는 것이 이 동작입니다.
- 4xx 요청 쪽 문제: 요청이 잘못됐거나, 인증이나 권한이 없거나, 대상이 없습니다. 운영자가 가장 많이 만나는 묶음입니다.
- 5xx 서비스 쪽 문제: 서버 내부 오류나 일시적 장애입니다. 보통 잠시 뒤 다시 시도합니다.

### 2. 자주 보는 상태 코드

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/entra-error-layers-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/entra-error-layers.png" | relative_url }}" alt="로그인 단계에서는 AADSTS, 호출 단계에서는 401·403·404·429·5xx가 나오는 구조" loading="lazy"></picture>

*그림 1. 로그인 단계와 호출 단계에서 나오는 오류*

- **200 OK, 201 Created, 204 No Content**: 성공. 201은 새로 만들어짐, 204는 성공했지만 돌려줄 내용이 없음입니다.
- **302 Found(리디렉션)**: 로그인 화면으로 보내는 정상 동작입니다. 같은 주소를 계속 오가며 멈추면 쿠키나 세션 문제를 의심합니다.
- **400 Bad Request**: 요청 형식이 잘못됐습니다. 스크립트의 필터 문법, 빠진 값, 잘못된 ID 형식이 흔한 원인입니다.
    - 로그인 토큰 요청이 실패할 때도 400과 함께 AADSTS 번호가 오는 경우가 많습니다.
- **401 Unauthorized**: 인증 정보(토큰)가 없거나, 만료됐거나, 이 리소스용이 아닙니다. 이름은 Unauthorized지만 실제 뜻은 "인증이 안 됨"에 가깝습니다.
- **403 Forbidden**: 누구인지는 확인됐지만 그 작업을 할 권한이 없습니다. Graph에서는 필요한 라이선스가 없을 때도 403이 나올 수 있습니다(문서).
- **404 Not Found**: 대상이 없습니다. ID나 이름 오타, 다른 테넌트, 이미 삭제된 개체를 확인합니다.
- **409 Conflict**: 현재 상태와 충돌합니다. 같은 이름의 개체가 이미 있거나 동시에 고친 경우입니다.
- **429 Too Many Requests**: 너무 많이 요청해서 잠시 막혔습니다(스로틀링, throttling). 응답의 Retry-After 헤더에 적힌 초만큼 기다렸다가 다시 시도합니다(문서).
- **500, 503, 504**: 서비스 쪽 오류, 일시적 사용 불가, 시간 초과입니다. 잠시 뒤 다시 시도하고, 계속되면 서비스 상태(Microsoft 365 관리 센터의 Service health)를 확인합니다.

### 3. 가장 헷갈리는 401과 403

회사 건물에 비유해 보겠습니다. 401은 출입증을 안 가져왔거나, 기한이 지났거나, 다른 건물 출입증을 낸 경우입니다. **토큰** 문제이니 다시 로그인해 새 토큰을 받고, 토큰이 이 리소스(예: Graph)용인지 확인합니다.

403은 출입증은 정상인데 3층 서버실 출입 권한이 없는 경우입니다. **권한** 문제이니 역할(Entra 역할, Azure RBAC)이나 앱 권한(스코프), 라이선스를 확인합니다.

#### 같은 스크립트, 다른 오류

밤새 돌던 사용자 조회 스크립트가 아침에 전부 401로 실패합니다. 토큰이 만료된 것이라 다시 접속(`Connect-MgGraph`)하자 정상입니다.

같은 스크립트에 사용자 사용 안 함 기능을 넣자 이번에는 403과 `Authorization_RequestDenied`가 납니다. 이번에는 토큰이 아니라 권한(쓰기 스코프와 역할)이 모자란 것입니다.

| 구분 | 401 | 403 |
|---|---|---|
| 한 줄 뜻 | 인증 안 됨 | 권한 없음 |
| 먼저 볼 것 | 토큰 유무, 만료, 대상 | 역할, 스코프, 라이선스, 범위 |
| 다시 로그인하면 | 대부분 해결 | 권한이 없으면 그대로 |

조건부 액세스가 걸린 리소스에서는 Graph가 `403 Forbidden`과 함께 `error=insufficient_claims`를 돌려줄 수 있습니다. 권한이 아니라 "추가 조건(예: MFA)을 채워서 다시 로그인하라"는 뜻입니다(문서).

### 4. AADSTS 오류 읽는 법

**AADSTS**는 Entra ID의 로그인 서버(STS, 보안 토큰 서비스)가 돌려주는 오류 번호입니다. 로그인 화면의 추가 정보(More details)나 토큰 요청의 응답에 나옵니다. 토큰 응답은 대략 이런 모양입니다(문서 예시를 줄임).

```json
{
  "error": "invalid_grant",
  "error_description": "AADSTS50126: ... Trace ID: ... Correlation ID: ... Timestamp: ...",
  "error_codes": [50126],
  "trace_id": "...",
  "correlation_id": "..."
}
```

- `error`: 큰 분류입니다. 예를 들면 다음과 같습니다.
    - `invalid_grant`는 인증 재료(코드, 토큰, 암호)가 유효하지 않음
    - `interaction_required`는 사용자가 직접 추가 단계(MFA 등)를 해야 함
    - `invalid_client`는 앱 자격 증명이 잘못됨
    - `temporarily_unavailable`은 서버가 잠시 바쁨
- `error_description`: AADSTS 번호와 설명입니다. 사람이 읽는 설명이라 문구는 바뀔 수 있습니다.
- `correlation_id`, `trace_id`, `timestamp`: **로그인 로그에서 같은 건을 찾는 열쇠**입니다. 사용자에게 오류 화면을 받을 때 이 값과 시각을 꼭 받아 둡니다.

번호의 최신 설명은 `https://login.microsoftonline.com/error?code=50126`처럼 번호를 넣어 공식 조회 페이지에서 확인할 수 있습니다(문서). 관리자는 Entra ID > Monitoring & health > Sign-in logs에서 같은 시각의 실패 항목을 열어 오류 코드와 실패 사유, 적용된 조건부 액세스 정책을 함께 봅니다.

### 5. Graph와 Azure 오류 읽는 법

로그인은 성공하고 API를 호출하다 실패하면, HTTP 상태 코드와 함께 서비스별 오류 코드가 옵니다.

- **Microsoft Graph**: `{"error": {"code": "...", "message": "...", "innerError": {"request-id": "...", "date": "..."}}}` 형식입니다.
    - 프로그램은 `code`를 기준으로 판단하고, `message`는 사람이 읽는 참고용입니다(문서).
    - 자주 보는 예 `InvalidAuthenticationToken`(401): 토큰이 잘못됐거나 만료됨
    - 자주 보는 예 `Authorization_RequestDenied`(403): "Insufficient privileges to complete the operation." 앱 권한(스코프)이나 역할이 모자람
- **Azure(Resource Manager)**: `AuthorizationFailed`(403)가 대표적입니다. 메시지에 어떤 작업(action)을 어느 범위(scope)에서 하려다 막혔는지 나오므로, 그 범위의 Azure 역할을 확인합니다(문서).
- **Graph PowerShell**: 오류 출력에 `Status: 403 (Forbidden)`, `ErrorCode: Authorization_RequestDenied`처럼 두 값이 함께 나옵니다. 필요한 권한은 `Find-MgGraphCommand`로 찾습니다(문서).

#### 메시지에서 범위 읽기

`The client 'ops@contoso.com' ... does not have authorization to perform action 'Microsoft.Compute/virtualMachines/write' over scope '/subscriptions/.../resourceGroups/rg-prod'`

이 메시지는 "VM 만들기(write)를 rg-prod 범위에서 할 권한이 없다"는 뜻입니다. rg-prod에 Virtual Machine Contributor 같은 역할이 있는지 확인합니다.

### 6. 오류를 직접 보는 곳

- **Entra 로그인 로그**: Entra ID > Monitoring & health > Sign-in logs. AADSTS 번호, 실패 사유, 조건부 액세스 결과가 남습니다.
- **브라우저 개발자 도구**: F12 > Network(네트워크) 탭의 Status 열에서 각 요청의 상태 코드를 봅니다. 공유할 때는 토큰이나 개인 정보가 담긴 헤더를 지웁니다.
- **Azure 활동 로그**: Azure 포털 > 해당 리소스 그룹 > Activity log. 실패한 작업과 AuthorizationFailed 메시지가 남습니다.
- **Graph Explorer**: 같은 요청을 직접 보내 상태 코드와 오류 본문을 확인하고, 권한(Modify permissions) 탭에서 필요한 동의를 확인합니다.

### 7. 이 시리즈의 오류 코드 한 줄 설명

**로그인: 계정과 암호**

- **AADSTS50126**: 사용자 이름 또는 암호가 틀림 ([50126 글]({{ "/iam/troubleshooting/aadsts50126-wrong-password/" | relative_url }}))
- **AADSTS50034**: 이 테넌트에 그런 계정이 없음(UPN 오타, 다른 테넌트 계정)
- **AADSTS50053**: 여러 번 틀려 잠김, 또는 악성 IP에서 온 로그인이라 차단
- **AADSTS50055**: 암호가 만료됨
- **AADSTS50057**: 계정이 사용 안 함 상태

**로그인: MFA** ([50076 글]({{ "/iam/troubleshooting/aadsts50076-mfa-required/" | relative_url }}))

- **AADSTS50076**: MFA를 해야 접근할 수 있음
- **AADSTS50079, 50072**: MFA를 해야 하는데 등록된 방법이 없음(등록 필요)
- **AADSTS50074**: MFA가 요구됐지만 통과하지 못함

**로그인: 조건부 액세스와 보안 기본값** ([53003 글]({{ "/iam/troubleshooting/aadsts53003-blocked-by-ca/" | relative_url }}))

- **AADSTS53003**: 조건부 액세스 정책이 차단함
- **AADSTS53000**: 준수 기기가 필요한데 기기가 준수 상태가 아님
- **AADSTS53001**: 도메인(하이브리드) 조인 기기가 필요함
- **AADSTS53002**: 승인된 앱이 아님
- **AADSTS530035**: 조건부 액세스가 아니라 보안 기본값이 차단함(예: 디바이스 코드 흐름) ([실제 사례]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }}))

**앱: 할당과 동의**

- **AADSTS50105**: 앱이 "할당 필요"인데 사용자가 할당되지 않음 ([50105 글]({{ "/iam/troubleshooting/aadsts50105-app-not-assigned/" | relative_url }}))
- **AADSTS65001**: 이 앱 사용에 동의한 적이 없음 ([65001 글]({{ "/iam/troubleshooting/aadsts65001-consent-required/" | relative_url }}))
- **AADSTS90093**: 사용자 동의가 꺼져 있거나, 사용자가 줄 수 없는 권한을 요청함
- **AADSTS90094**: 관리자만 줄 수 있는 권한을 요청함
- **AADSTS900941, 900981**: 위험한 앱으로 판단되어 관리자 동의가 필요함 / 관리자 동의 요청이 접수됨

**외부 사용자** ([50020 글]({{ "/iam/troubleshooting/aadsts50020-guest-not-in-tenant/" | relative_url }}))

- **AADSTS50020**: 이 테넌트에 없는 외부 계정으로 로그인함(다른 계정으로 로그인, 초대 안 됨 등)
- **AADSTS90072**: 게스트 쪽 홈 테넌트 로그에 남는 같은 상황의 코드
- **AADSTS90071**: B2B direct connect(Teams 공유 채널)에서 MFA 신뢰 설정이 필요함

**하이브리드: PTA** ([PTA 글]({{ "/iam/troubleshooting/pta-agent-sign-in-fails/" | relative_url }}))

- **AADSTS80001**: 사용할 수 있는 인증 에이전트가 없거나 AD에 연결할 수 없음
- **AADSTS80002**: 에이전트의 암호 검증 요청이 시간 초과
- **AADSTS50144**: 사내 AD 암호가 만료됨

**암호 재설정(SSPR)** ([SSPR 글]({{ "/iam/troubleshooting/sspr-cannot-reset/" | relative_url }}))

- **SSPR_0009**: 조직에서 SSPR이 꺼져 있음
- **SSPR_0010**: 사내 AD 쓰기 저장(writeback)이 꺼져 있음
- **SSPR_0011**: 사용자에게 SSPR 정책이 적용되지 않음
- **SSPR_0012**: 라이선스가 없음

**호출: 권한** ([403 글]({{ "/iam/troubleshooting/signed-in-but-403/" | relative_url }}))

- **403 Forbidden, Authorization_RequestDenied**(Graph): 앱 권한(스코프)이나 역할이 모자람
- **403, AuthorizationFailed**(Azure): 그 범위에서 그 작업을 할 Azure 역할이 없음

### 8. 관련 트러블슈팅

- 로그인은 되는데 권한이 없을 때: [로그인은 되는데 403·AuthorizationFailed가 나올 때]({{ "/iam/troubleshooting/signed-in-but-403/" | relative_url }})
- 스크립트가 전부 실패할 때: [조회 스크립트 결과가 전부 실패로 나옴: 토큰 만료와 오류 유형 구분]({{ "/m365/troubleshooting/script-all-fail-token-expired/" | relative_url }})
- 403과 404를 나눠 본 사례: [사용 현황 보고서가 '데이터 없음'이고 Graph는 404 UnknownTenantId]({{ "/m365/troubleshooting/usage-report-no-data/" | relative_url }})

### 9. 확인 문제

<details markdown="1">
<summary>1. Graph 호출이 401을 돌려줍니다. 역할부터 바꿔야 하나요?</summary>

아닙니다. 401은 권한보다 **토큰** 문제입니다. 다시 로그인해 새 토큰을 받고, 토큰이 Graph용인지 확인합니다.

그래도 같은 작업이 403이 되면 그때 권한을 봅니다.

</details>

<details markdown="1">
<summary>2. 사용자가 "AADSTS53003"이 떴다고 합니다. 어디부터 보나요?</summary>

로그인 단계 오류이므로 Entra 로그인 로그에서 같은 시각의 실패 항목을 열고, Conditional Access 탭에서 Failure로 표시된 정책을 확인합니다. 사용자에게 상관 관계 ID(Correlation ID)를 받아 두면 빨리 찾습니다.

</details>

<details markdown="1">
<summary>3. 대량 조회 스크립트가 중간부터 429를 돌려줍니다. 어떻게 하나요?</summary>

요청이 너무 많아 잠시 막힌 것입니다. 응답의 Retry-After 값만큼 기다렸다가 다시 시도하고, 한 번에 보내는 요청 수를 줄입니다.

</details>

### 10. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (7건)</summary>

- AADSTS 오류 응답 형식, error 값, 오류 조회 페이지: [Microsoft Entra authentication and authorization error codes](https://learn.microsoft.com/entra/identity-platform/reference-error-codes)
- Graph의 HTTP 상태 코드와 오류 형식, 403 insufficient_claims, 라이선스 없을 때 403: [Microsoft Graph error responses and resource types](https://learn.microsoft.com/graph/errors)
- Graph 401, 403 해결: [Resolve Microsoft Graph authorization errors](https://learn.microsoft.com/graph/resolve-auth-errors)
- Authorization_RequestDenied: [Troubleshoot Authorization_RequestDenied error with Microsoft Graph](https://learn.microsoft.com/troubleshoot/entra/entra-id/app-integration/troubleshoot-authorization-requestdenied-graph-api)
- 429와 Retry-After: [Microsoft Graph throttling guidance](https://learn.microsoft.com/graph/throttling)
- AuthorizationFailed: [Troubleshoot Azure RBAC](https://learn.microsoft.com/azure/role-based-access-control/troubleshooting)
- Graph PowerShell 403과 Find-MgGraphCommand: [Troubleshooting common errors in Microsoft Graph PowerShell](https://learn.microsoft.com/powershell/microsoftgraph/troubleshooting)

</details>
