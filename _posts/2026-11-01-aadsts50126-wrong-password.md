---
title: "[Troubleshooting] 로그인할 때 AADSTS50126(사용자 이름 또는 암호가 잘못됨)이 나올 때"
date: 2026-11-01 09:01:00 +0900
categories: [iam, troubleshooting]
area: 로그인·권한
seq: 1
tags: [Troubleshooting, Entra ID, AADSTS50126, AADSTS50053, 스마트 잠금, PHS, PTA, 로그인 로그]
excerpt: "암호가 맞다는데 50126이 나오는 경우를 계정 없음(50034), 잠김(50053), 사용 안 함(50057), 하이브리드 동기화·UPN 문제로 나눠 보는 대처 가이드"
---

> Microsoft Learn 공식 문서(2026-11-01 확인)를 기준으로 쓴 대처 가이드입니다. 특정 테넌트에서 재현한 기록은 아닙니다. 개념은 [Entra ID 핵심 개념 — 인증 편]({{ "/iam/entra-id-authentication/" | relative_url }})을 함께 보세요. 오류 번호와 HTTP 상태 코드가 낯설면 [오류 코드 읽는 법]({{ "/iam/entra-id-error-codes/" | relative_url }})을 먼저 보세요.

## 요약

- **증상**: 로그인 화면에 "계정 또는 암호가 잘못되었습니다"가 나오고, 로그인 로그의 오류 코드가 50126(InvalidUserNameOrPassword)
- **먼저 볼 곳**: Entra 관리 센터 로그인 로그의 오류 코드와 실패 사유. 비슷한 코드(50034·50053·50057·50055)와 구분
- **흔한 원인**
    - 실제로 암호를 틀림
    - 다른 계정(UPN)으로 로그인
    - 하이브리드에서 바꾼 암호가 아직 동기화 안 됨
    - PTA 환경에서 온-프레미스 UPN과 클라우드 UPN이 다름
- **대처**: 원인별로 SSPR 안내, UPN 확인, 동기화 확인, PTA 점검
- **예방**: SSPR 사용, 패스키 등 암호 없는 로그인으로 전환

---

## 전체 내용

### 1. 증상

사용자가 "암호가 맞는데 로그인이 안 된다"고 문의합니다. 화면에는 계정 또는 암호가 잘못됐다는 안내가 나오고, 관리자가 로그인 로그를 보면 오류 코드 **50126**이 찍혀 있습니다.

### 2. 먼저 확인할 것 — 정말 50126인가

비슷해 보이지만 원인이 전혀 다른 코드가 있습니다. **로그인 로그에서 정확한 코드부터 확인**합니다.

- GUI 경로: Microsoft Entra 관리 센터 > Entra ID > Monitoring & health(모니터링 및 상태) > Sign-in logs(로그인 로그)
- 필터: 사용자 이름, 날짜, 상태 = 실패
- 실패한 항목을 열어 **Sign-in error code**와 **Failure reason**을 봅니다.

| 코드 | 이름(문서) | 뜻 | 대처 방향 |
|---|---|---|---|
| **50126** | InvalidUserNameOrPassword | 사용자 이름 또는 암호가 틀림 | 이 글의 3번 |
| 50034 | UserAccountNotFound | 이 테넌트에 그런 계정이 없음 | UPN 오타, 다른 테넌트 계정인지 확인 |
| 50053 | IdsLocked 등 | 너무 여러 번 틀려 **잠김**, 또는 악성 IP에서 온 로그인이라 차단 | 4번(스마트 잠금) |
| 50057 | UserDisabled | 계정이 **사용 안 함** 상태 | 의도한 비활성화인지 확인 |
| 50055 | InvalidPasswordExpiredPassword | 암호가 **만료**됨 | 암호 변경 안내 |

### 3. 원인별 대처 (50126)

- **실제로 암호를 틀림**
    - 확인 방법: 같은 사용자의 최근 로그인 성공·실패 기록
    - 대처: 사용자에게 SSPR(`https://aka.ms/sspr`)로 직접 재설정 안내
- **다른 계정으로 로그인**
    - 확인 방법: 로그인 로그의 사용자 이름이 회사 UPN과 같은지
    - 대처: 브라우저에 저장된 개인 계정·다른 회사 계정이 아닌지 확인. 사번이나 이메일 별칭이 아니라 **UPN**으로 로그인해야 함
- **(하이브리드·PHS) 사내에서 바꾼 암호가 아직 클라우드에 없음**
    - 확인 방법: 사내 AD에서 암호를 바꾼 시각과 로그인 시각 비교
    - 대처: PHS는 약 2분 주기로 동기화됨. 잠시 후 다시 시도. 기본값에서는 "다음 로그온 시 암호 변경" 플래그가 걸린 임시 암호가 동기화되지 않음(사용자가 직접 바꿀 때까지). Connect의 ForcePasswordChangeOnLogOn 기능을 켜면 임시 암호도 동기화되고 클라우드에서 변경을 요구함(SSPR·쓰기 저장 사용 시 권장)
- **(하이브리드·PTA) 사내 UPN과 클라우드 UPN이 다름**
    - 확인 방법: PTA 에이전트 서버에서 문서의 진단 명령으로 테스트
    - 대처: 라우팅할 수 없는 사내 UPN이면 대체 로그인 ID 구성이 필요

**예시 — 월요일 아침의 50126**

금요일 저녁에 사내 PC에서 암호 만료 안내를 받고 암호를 바꾼 직원이, 주말에 집에서 Outlook 웹에 옛 암호로 로그인하려다 50126이 납니다. 사내 PC에서 바꾼 새 암호는 PHS로 이미 동기화됐으므로 **새 암호로 로그인하면 해결**됩니다. 휴대폰 메일 앱처럼 옛 암호를 저장해 둔 기기가 계속 시도하면 4번의 잠금으로 이어질 수 있으니, 그 기기의 암호도 함께 바꾸도록 안내합니다.

### 4. 함께 알아 둘 것 — 스마트 잠금(Smart lockout)

암호를 여러 번 틀리면 50053으로 바뀝니다. Entra ID의 **스마트 잠금**은 모든 테넌트에서 항상 켜져 있습니다(문서).

- **잠금 임계값**: 실패 10회
- **첫 잠금 시간**: 60초. 반복될수록 길어짐
- **같은 틀린 암호 반복**: 최근 틀린 암호 3개의 해시를 기억해, 같은 암호를 여러 번 넣은 것은 한 번으로 셈. 단, PTA를 켠 환경에서는 이 해시 추적이 동작하지 않음
- **해제 방법**: 시간이 지나기를 기다림. 또는 SSPR에서 "암호를 잊었습니다"로 재설정하면 잠금 시간이 0으로 초기화됨. 관리자가 암호를 재설정해도 풀림
- **값 변경**: Entra ID > Authentication methods > Password protection. 사용자 지정은 P1 이상

**PTA를 쓰는 하이브리드 환경**이라면 문서 권장대로 Entra 잠금 임계값은 AD보다 **작게**, 잠금 시간은 AD보다 길게 설정합니다. 그래야 클라우드 쪽 공격이 사내 AD 계정을 잠그기 전에 Entra에서 먼저 걸러집니다.

### 5. 해결 확인

- 로그인 로그에서 같은 사용자의 다음 시도가 **성공**인지 확인합니다.
- 실패가 계속 쌓이는데 시도 위치가 사용자와 무관하다면, 암호 스프레이 등 공격일 수 있으므로 **위험한 로그인(ID Protection)** 보고서도 확인합니다(P2).

### 6. 예방

- SSPR을 켜 두면 헬프데스크 없이 사용자가 직접 해결합니다.
- 패스키처럼 **암호 없는 로그인**으로 옮기면 이 유형의 문의 자체가 줄어듭니다.

## 근거 자료

- AADSTS 오류 코드 정의(50126, 50034, 50053, 50055, 50057): [Microsoft Entra authentication and authorization error codes](https://learn.microsoft.com/entra/identity-platform/reference-error-codes)
- 스마트 잠금 기본값과 동작, PTA 환경 권장 설정: [Protect user accounts with Microsoft Entra smart lockout](https://learn.microsoft.com/entra/identity/authentication/howto-password-smart-lockout)
- PHS 동기화 주기: [Choose the right authentication method](https://learn.microsoft.com/entra/identity/hybrid/connect/choose-ad-authn)
- 임시 암호와 ForcePasswordChangeOnLogOn: [Password hash synchronization](https://learn.microsoft.com/entra/identity/hybrid/connect/how-to-connect-password-hash-synchronization)
- PTA에서 UPN이 다를 때: [Troubleshoot pass-through authentication](https://learn.microsoft.com/entra/identity/hybrid/connect/tshoot-connect-pass-through-authentication)
