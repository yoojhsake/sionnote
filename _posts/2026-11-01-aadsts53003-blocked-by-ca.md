---
title: "[Troubleshooting] AADSTS53003: 조건부 액세스 정책 때문에 접근이 차단될 때"
date: 2026-11-01 09:03:00 +0900
categories: [iam, troubleshooting]
area: 로그인·권한
seq: 3
tags: [Troubleshooting, Entra ID, 조건부 액세스, AADSTS53003, What If, 로그인 로그, 보고서 전용]
excerpt: "53003 차단 화면을 받았다면 로그인 로그의 조건부 액세스 탭부터. 어떤 정책이 왜 막았는지 찾고 What If로 확인하는 법"
---

"이 리소스에 액세스할 수 없습니다" 화면에 53003이 보이면 조건부 액세스 정책이 막은 것입니다. 로그인 로그의 Conditional Access 탭에서 결과가 Failure인 정책을 찾으면 어떤 정책이 왜 막았는지 알 수 있고, Teams만 열었는데 SharePoint나 Exchange Online 정책에 걸릴 수 있는 점(서비스 종속성)도 설명합니다.

## 요약

- 로그인 로그의 Conditional Access 탭에서 Failure인 정책이 차단 원인임
- 의도한 차단이 아니면 정책 범위를 고친 뒤 보고서 전용으로 먼저 검증함
- What If는 서비스 종속성을 계산하지 않아 Teams 차단 원인을 놓칠 수 있음

> Microsoft Learn 문서(2026-11-01 확인) 기준이며, 테넌트에서 재현하지는 않았습니다. 함께 볼 글: [Entra ID 핵심 개념: 접근 제어 편]({{ "/iam/entra-id-access-control/" | relative_url }}), [오류 코드 읽는 법]({{ "/iam/entra-id-error-codes/" | relative_url }}).

---

## 전체 내용

### 1. 증상

- "이 리소스에 액세스할 수 없습니다" 화면의 More details에 53003, 요청 ID, Correlation ID, 시각이 보입니다(로그 찾기에 씀).
- 가상 예시: "허용 국가 외 차단" 정책이 있는 회사의 출장 직원이 Teams 로그인 때 53003을 받습니다.

### 2. 원인 및 분석

로그인 로그 Conditional Access 탭에서 결과가 Failure인 정책이 막은 정책입니다([문서](https://learn.microsoft.com/entra/identity/conditional-access/troubleshoot-conditional-access)).

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/ts-aadsts53003-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/ts-aadsts53003.png" | relative_url }}" alt="로그인 로그에서 차단 정책을 찾고 상황별로 대처하는 순서" loading="lazy"></picture>

*그림 1. 차단 정책을 찾는 순서와 상황별 대처*

53000~53002와 530035(보안 기본값, [별도 사례 글]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }}))은 원인이 다릅니다(접힌 부분).

헷갈리는 원인은 서비스 종속성입니다. Teams 로그인도 채팅, Outlook 일정, SharePoint 파일 등 여러 리소스를 요청해, 정책의 Audience(요청 리소스 목록) 중 하나가 대상이면 적용됩니다.

<details markdown="1">
<summary>확인 과정 자세히 보기</summary>

#### 비슷한 코드

- 53003(BlockedByConditionalAccess): 정책이 차단함
- 53000(DeviceNotCompliant): 준수 기기가 필요한데 기기가 준수 상태가 아님
- 53001(DeviceNotDomainJoined): 도메인(하이브리드) 조인 기기가 필요함
- 53002(ApplicationUsedIsNotAnApprovedApp): 승인된 앱이 아님
- 530035(BlockedBySecurityDefaults): 조건부 액세스가 아니라 **보안 기본값**이 차단함

#### 어떤 정책이 막았나

1. Entra ID > Monitoring & health > Sign-in logs로 이동합니다(최소 Reports Reader 역할).
2. 필터에 Correlation ID(사용자가 알려 준 값) 또는 사용자 이름과 시간을 넣습니다. Conditional Access = Failure 필터도 유용합니다.
3. 해당 로그인을 열고 Conditional Access 탭을 봅니다. 결과가 **Failure**인 정책이 막은 정책입니다.
4. 정책 줄 오른쪽 …을 누르면 정책 세부 정보가 나옵니다.
    - 왼쪽은 로그인 때 수집된 정보, 오른쪽은 그 정보가 정책 조건에 맞았는지입니다.
    - 조건이 모두 맞을 때만 정책이 적용됩니다.
5. 그래도 모르겠으면 Basic info > Troubleshoot Event(로그인 진단)를 실행합니다.

Azure 포털처럼 앱은 Azure portal인데 리소스는 Azure Resource Manager로 찍히는 경우도 있어, 정책을 만들 때 관련 앱과 리소스를 함께 대상으로 잡아야 합니다.

#### 재현 없이 미리 확인: What If 도구

- 위치: Entra ID > Conditional Access > Policies > What If
- 필수 입력: 사용자(또는 워크로드 ID), 대상 리소스, 기기 플랫폼, 클라이언트 앱. 나머지는 비우면 "없음"으로 계산됩니다.
- 결과: 적용되는 정책(필요한 허용·세션 제어 포함)과 적용되지 않는 정책(처음으로 맞지 않은 조건이 이유로 표시).
- 주의: What If는 **서비스 종속성은 계산하지 않습니다.** 예를 들어 Teams를 테스트해도 Exchange Online에 걸린 정책은 결과에 안 나옵니다.

#### 해외 출장자가 Teams에서 차단된 경우

로그인 로그의 Conditional Access 탭에 위치 차단 정책이 Failure로 찍혀 있고, 세부 정보에서 위치 조건이 맞았다고 나옵니다.

출장이 승인된 경우라면 정책을 끄지 않고, 출장자 그룹을 기간 한정으로 제외하거나 출장 국가를 명명된 위치에 잠시 추가합니다. 출장이 끝나면 원래대로 되돌립니다.

</details>

### 3. 결론

`사용자·위치·요청 리소스(Audience)가 정책 조건에 모두 맞음 → 정책이 차단 → 53003`

### 4. 권고방안

1. 조치
    - 관리자까지 막혔다면 [조건부 액세스 실수로 관리자가 잠겼을 때]({{ "/iam/troubleshooting/ca-lockout-emergency-access/" | relative_url }})의 긴급 액세스 절차부터
    - 의도하지 않은 차단: 범위를 고치고 보고서 전용으로 확인 뒤 켬
    - 승인된 출장: 출장자 그룹 기간 한정 제외나 명명된 위치 임시 추가 후 원복
2. 확인: 다음 로그인의 Conditional Access 탭에 그 정책이 Failure로 없으면 해결입니다(What If는 서비스 종속성을 계산하지 않음).
3. 예방: 새 정책은 보고서 전용 → 로그 확인 → 켜기. 정책 이름에 목적, 대상, 담당 팀(문서 권장). 보호된 작업(Protected actions)으로 정책 생성·변경·삭제에 추가 인증 요구
4. 하지 말 것: 예외 때문에 정책 자체를 끄기

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (4건)</summary>

- 53000~53004, 530035 정의: [Microsoft Entra authentication and authorization error codes](https://learn.microsoft.com/entra/identity-platform/reference-error-codes)
- 로그인 로그 조건부 액세스 탭, 정책 세부 정보, 서비스 종속성, Audience: [Troubleshoot sign-in problems with Conditional Access](https://learn.microsoft.com/entra/identity/conditional-access/troubleshoot-conditional-access)
- What If 도구 위치, 입력, 한계: [Troubleshoot Conditional Access with the What If tool](https://learn.microsoft.com/entra/identity/conditional-access/what-if-tool)
- 정책 이름 규칙, 보호된 작업, 문제 해결 때 모을 정보: [Plan a Conditional Access deployment](https://learn.microsoft.com/entra/identity/conditional-access/plan-conditional-access)

</details>
