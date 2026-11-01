---
title: "[Troubleshooting] 로그인할 때 AADSTS50126(사용자 이름 또는 암호가 잘못됨)이 나올 때"
date: 2026-11-01 09:01:00 +0900
categories: [iam, troubleshooting]
area: 로그인·권한
seq: 1
tags: [Troubleshooting, Entra ID, AADSTS50126, AADSTS50053, 스마트 잠금, PHS, PTA, 로그인 로그]
excerpt: "암호가 맞다는데 50126이 뜰 때. 로그인 로그 코드로 계정 없음·잠김·UPN·동기화 문제를 가른다"
---

사용자는 암호가 맞다는데 로그인 화면에는 "계정 또는 암호가 잘못되었습니다"(AADSTS50126)가 뜹니다. 실제로 틀린 경우 말고도 다른 UPN으로 로그인했거나 하이브리드에서 바꾼 암호가 아직 동기화되지 않은 경우가 있어서, 로그인 로그의 오류 코드부터 보면 갈래가 나뉩니다.

## 요약

- 대부분 실제로 암호를 틀렸거나 다른 UPN으로 로그인한 경우임
- 로그인 로그의 정확한 오류 코드로 잠김이나 계정 없음과 먼저 구분함
- 옛 암호를 저장한 기기가 계속 시도하면 스마트 잠금으로 이어질 수 있음

> Microsoft Learn 문서(2026-11-01 확인) 기준입니다. 샌드박스 테넌트에서 일부러 암호를 틀려 로그인 로그를 확인한 화면(2장)을 '2. 원인 및 분석'에 접어 두었습니다. 함께 볼 글: [Entra ID 핵심 개념: 인증 편]({{ "/iam/entra-id-authentication/" | relative_url }}), [오류 코드 읽는 법]({{ "/iam/entra-id-error-codes/" | relative_url }}).

---

## 전체 내용

### 1. 증상

- 사용자는 "암호가 맞다"고 하는데 로그인 로그에는 50126이 있습니다.
- 사례: 금요일 저녁 사내 PC에서 만료된 암호를 바꾼 직원이 주말에 집에서 Outlook 웹에 옛 암호로 로그인합니다.

### 2. 원인 및 분석

50126(InvalidUserNameOrPassword)은 이름 또는 암호가 틀렸다는 뜻입니다([문서](https://learn.microsoft.com/entra/identity-platform/reference-error-codes)). 50034, 50053, 50057, 50055와는 로그인 로그의 정확한 코드로 구분합니다.

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/ts-aadsts50126-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/ts-aadsts50126.png" | relative_url }}" alt="AADSTS50126의 4가지 원인과 대처" loading="lazy"></picture>

*그림 1. 원인과 대처 4가지*

<details markdown="1">
<summary>원인별 확인과 대처 자세히 보기</summary>

- **실제로 암호를 틀림**
    - 확인 방법: 같은 사용자의 최근 로그인 성공·실패 기록
    - 대처: 사용자에게 SSPR(`https://aka.ms/sspr`)로 직접 재설정 안내
- **다른 계정으로 로그인**
    - 확인 방법: 로그인 로그의 사용자 이름이 회사 UPN과 같은지
    - 대처: 브라우저에 저장된 개인 계정이나 다른 회사 계정이 아닌지 확인. 사번이나 이메일 별칭이 아니라 **UPN**으로 로그인해야 함
- **(하이브리드·PHS) 사내에서 바꾼 암호가 아직 클라우드에 없음**
    - 확인 방법: 사내 AD에서 암호를 바꾼 시각과 로그인 시각 비교
    - 대처: PHS는 약 2분 주기로 동기화됨. 잠시 후 다시 시도
    - 임시 암호: 기본값에서는 "다음 로그온 시 암호 변경" 플래그가 걸린 임시 암호가 동기화되지 않음(사용자가 직접 바꿀 때까지)
    - Connect의 ForcePasswordChangeOnLogOn 기능을 켜면 임시 암호도 동기화되고 클라우드에서 변경을 요구함(SSPR·쓰기 저장 사용 시 권장)
- **(하이브리드·PTA) 사내 UPN과 클라우드 UPN이 다름**
    - 확인 방법: PTA 에이전트 서버에서 문서의 진단 명령으로 테스트
    - 대처: 라우팅할 수 없는 사내 UPN이면 대체 로그인 ID 구성이 필요

</details>

샌드박스에서 암호를 일부러 한 번 틀리자 로그인 로그에 50126 실패 항목이 남았습니다.

<details markdown="1">
<summary>확인 과정 자세히 보기</summary>

#### 정말 50126인가

비슷해 보이지만 원인이 전혀 다른 코드가 있습니다. **로그인 로그에서 정확한 코드부터 확인**합니다.

- GUI 경로: Microsoft Entra 관리 센터 > Entra ID > Monitoring & health(모니터링 및 상태) > Sign-in logs(로그인 로그)
- 필터: 사용자 이름, 날짜, 상태 = 실패
- 실패한 항목을 열어 **Sign-in error code**와 **Failure reason**을 봅니다.

| 코드 | 이름(문서) | 뜻 | 대처 방향 |
|---|---|---|---|
| **50126** | InvalidUserNameOrPassword | 사용자 이름 또는 암호가 틀림 | 그림 1의 원인별 대처 |
| 50034 | UserAccountNotFound | 이 테넌트에 그런 계정이 없음 | UPN 오타, 다른 테넌트 계정인지 확인 |
| 50053 | IdsLocked 등 | 너무 여러 번 틀려 **잠김**, 또는 악성 IP에서 온 로그인이라 차단 | 아래 스마트 잠금 |
| 50057 | UserDisabled | 계정이 **사용 안 함** 상태 | 의도한 비활성화인지 확인 |
| 50055 | InvalidPasswordExpiredPassword | 암호가 **만료**됨 | 암호 변경 안내 |

**샌드박스에서 직접 확인한 로그**

시험 사용자로 로그인하면서 암호를 일부러 한 번 틀렸더니, 로그인 로그에 실패 항목이 남았습니다. 요청 ID, 계정, IP는 가렸습니다.

![로그인 이벤트 목록. OfficeHome 항목 중 상태가 실패인 행이 있음]({{ "/assets/images/2026/11/ts-aadsts50126-1-log-list.png" | relative_url }})

*그림 2. Entra ID > Monitoring & health > Sign-in logs. 같은 사용자의 OfficeHome 항목 중 상태가 "실패"인 행이 암호를 틀린 로그인입니다(바로 위 "중단됨"은 로그인 도중 멈춘 항목).*

![실패 항목의 기본 정보. 로그인 오류 코드 50126과 실패 이유가 표시됨]({{ "/assets/images/2026/11/ts-aadsts50126-2-log-detail.png" | relative_url }})

*그림 3. 실패 항목을 열면 기본 정보 탭에 로그인 오류 코드 50126과 실패 이유("Error validating credentials due to invalid username or password.")가 나옵니다. 추가 세부 정보도 "사용자가 올바른 자격 증명을 입력하지 않았다"는 일반적인 안내입니다.*

</details>

암호를 여러 번 틀리면 50053으로 바뀝니다. 스마트 잠금은 모든 테넌트에서 항상 켜져 있습니다(문서).

<details markdown="1">
<summary>스마트 잠금(Smart lockout) 기본값 보기</summary>

- 잠금 임계값 실패 10회, 첫 잠금 60초(반복될수록 길어짐)
- 최근 틀린 암호 3개의 해시를 기억해 같은 틀린 암호 반복은 한 번으로 셈. PTA 환경에서는 이 해시 추적이 동작하지 않음
- 해제: 시간이 지나기를 기다리거나, SSPR "암호를 잊었습니다" 재설정(잠금 시간 0으로 초기화) 또는 관리자 암호 재설정
- 값 변경: Entra ID > Authentication methods > Password protection(사용자 지정은 P1 이상)

</details>

### 3. 결론

`옛 암호 입력 → 자격 증명 검증 실패 → 50126 → 저장된 옛 암호로 계속 시도하면 50053`

사례는 새 암호가 PHS로 이미 동기화돼 있어 새 암호로 로그인하면 해결됩니다.

### 4. 권고방안

1. 조치
    - 원인별 대처(위 접힌 목록)를 따르고, 옛 암호를 저장한 기기(휴대폰 메일 앱 등)도 바꾸게 합니다.
    - SSPR을 켜면 사용자가 직접 풀고, 패스키 같은 암호 없는 로그인은 이 문의 자체를 줄입니다.
    - PTA 환경은 Entra 잠금 임계값을 AD보다 작게, 잠금 시간은 길게 둡니다(문서 권장). 클라우드 공격이 AD 계정을 잠그기 전에 Entra가 거릅니다.
2. 확인: 같은 사용자의 다음 시도가 성공이면 해결입니다. 실패가 쌓이고 위치가 사용자와 무관하면 암호 스프레이일 수 있으니 위험한 로그인(ID Protection) 보고서(P2)를 봅니다.

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (5건)</summary>

- AADSTS 오류 코드 정의(50126, 50034, 50053, 50055, 50057): [Microsoft Entra authentication and authorization error codes](https://learn.microsoft.com/entra/identity-platform/reference-error-codes)
- 스마트 잠금 기본값과 동작, PTA 환경 권장 설정: [Protect user accounts with Microsoft Entra smart lockout](https://learn.microsoft.com/entra/identity/authentication/howto-password-smart-lockout)
- PHS 동기화 주기: [Choose the right authentication method](https://learn.microsoft.com/entra/identity/hybrid/connect/choose-ad-authn)
- 임시 암호와 ForcePasswordChangeOnLogOn: [Password hash synchronization](https://learn.microsoft.com/entra/identity/hybrid/connect/how-to-connect-password-hash-synchronization)
- PTA에서 UPN이 다를 때: [Troubleshoot pass-through authentication](https://learn.microsoft.com/entra/identity/hybrid/connect/tshoot-connect-pass-through-authentication)

</details>
