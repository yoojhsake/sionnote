---
title: "[M365·Azure] 실측, Purview 규정 준수와 Azure 거버넌스: 감사, 보존, DLP, 레이블, Policy, 구독 권한 (전체 기록)"
date: 2026-10-22 13:00:00 +0900
categories: [m365]
phase: 운영 설정 실측
seq: 5
tags: [M365·Azure, 실측, Purview, 감사, DLP, 민감도 레이블, Azure Policy, 전체 기록]
excerpt: "8개 영역을 읽기만 해서 판독했더니 감사 로그 수집이 꺼져 있었고 보존 정책은 0건, Policy 할당도 0이었습니다."
---

Purview 규정 준수와 Azure 거버넌스는 손대지 않은 테넌트에서 실제로 어디까지 켜져 있을까요? 8개 영역을 읽기만 해서 판독했더니 통합 감사 로그 수집부터 꺼져 있었고(False), 보존 정책은 0건이었습니다.

## 요약

- 가장 큰 위험은 통합 감사 로그 수집 꺼짐(False, 내 PC PowerShell로 확인)
- 보존 정책 0건에 보존 레이블도 없음. DSPM for AI "시작하기" 4개는 모두 미완료
- DLP 3건 중 1건이 "알림과 함께 테스트", 민감도 레이블은 Microsoft 기본 5개
- Azure Policy 할당 0(준수율 100%는 리소스가 0이라서 나온 값), 구독 Owner 2건 모두 영구 활성
- EA/MCA 청구 범위 역할은 측정 불가(청구 범위 0건). "0건"과 "100%"는 통제가 없거나 권한이 없어 안 보인다는 뜻일 수 있음

Purview(감사, 보존, DLP, 민감도 레이블, DSPM for AI)와 Azure(Policy, 구독 Owner, 청구 범위) 8개 영역을 설정은 바꾸지 않고 읽어서 판독했습니다. 측정은 2026-10-22(목)부터 2026-10-23(금)까지 했고 **모든 측정은 읽기 전용**입니다. 시작, 평가판, 저장 버튼은 누르지 않았습니다. 방법은 [측정 방법 글]({{ "/m365/measurement-method/" | relative_url }})에 있고, 끝내 읽지 못한 항목은 아래 "끝내 확인하지 못한 것"에 시도 방법과 막힌 이유, 다음 방법을 적었습니다.

> 근거 표기: 조회 = 화면에서 직접 읽은 값, 문서 = Microsoft Learn, 확인 불가 = 시도했지만 확인하지 못한 값(시도 방법, 막힌 이유, 다음 방법 병기). 테넌트 ID, 구독 ID, 도메인은 게시하지 않았습니다. 개선 방안은 권고이며 이번에 실행하지 않았습니다.

---

## 전체 기록

### 1. 통합 감사 로그

<details markdown="1">
<summary>자세히 보기 (그림 1장)</summary>

- **GUI 경로**: Microsoft Purview 포털 > 감사 > 검색

화면을 열자 검색 폼이 회색으로 비활성이었고, "활동이 기록되고 있는지 확인하는 데 문제가 있다"는 문구와 함께 **"사용자 및 관리자 활동 기록 시작" 버튼**이 보였습니다(조회). 같은 화면을 다시 열어도 문구는 그대로이고 검색 버튼도 회색이라, 이 화면만으로는 기록 중인지 알 수 없었습니다. 버튼은 설정을 바꾸는 동작이라 누르지 않았습니다.

오류 문구만으로 감사가 꺼져 있다고 확정할 수는 없습니다. 문서에 따르면 감사가 켜져 있는지는 Exchange Online PowerShell(`UnifiedAuditLogIngestionEnabled`)로 확인합니다. 그런데 Cloud Shell에서 Exchange Online 로그인이 막혔습니다([AADSTS530035 글]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }})). 그래서 내 PC의 PowerShell에서 브라우저 로그인으로 `Get-AdminAuditLogConfig`의 감사 수집 항목을 읽었고, 수집 상태는 **꺼짐(False)** 이었습니다(10/26, 조회).

화면으로는 측정 불가였고, PowerShell 값으로 수집이 꺼져 있다는 것을 확인한 셈입니다. 문서에 따르면 감사를 켠 직후에는 반영까지 최대 60분이 걸립니다.

감사가 꺼져 있으면 사고가 나도 "누가 무엇을 했는지" 찾을 수 없습니다. Entra 감사 로그는 별도로 있어서, Identity 실측 글에서 Elevate access 기록은 확인할 수 있었습니다.

근거: [감사 활성화·비활성화](https://learn.microsoft.com/purview/audit-log-enable-disable), [감사 시작하기](https://learn.microsoft.com/purview/audit-get-started), [감사 로그 검색](https://learn.microsoft.com/purview/audit-search), [감사 솔루션 개요](https://learn.microsoft.com/purview/audit-solutions-overview) (감사 Standard 보관 180일은 문서 설명)

![Purview 감사 검색 화면]({{ "/assets/images/2026/10/m10-audit-retry.png" | relative_url }})
*그림 1. Purview 감사 검색 화면. "활동을 기록 중인지 파악하는 데 문제가 있습니다" 문구와 "사용자 및 관리자 활동 기록 시작" 버튼이 있고, 날짜 범위 입력란이 보입니다.*

</details>

### 2. 보존 정책

<details markdown="1">
<summary>자세히 보기 (그림 1장)</summary>

- **GUI 경로**: Purview > 데이터 수명 주기 관리 > 보존 정책

목록은 "0 items / No data available", 개요에는 "No retention labels detected"였습니다(조회). 역할 그룹이 제한되어 보이지 않을 수 있다는 배너도 있었습니다.

판독은 위험입니다. Teams, SharePoint, Exchange 어디에도 보존 정책이 없습니다. 배너 때문에 "실제로 0개"인지 "권한이 없어 안 보이는 것"인지는 확정하지 못했지만(권한 영향 확인 불가, 아래 목록), 화면 값 기준으로는 위험으로 읽습니다.

개선 방안(미실행)은 법적, 업무 요건에 맞춰 Teams 채팅과 채널 메시지, Exchange, SharePoint/OneDrive 보존 정책을 설계하는 것입니다. 보존은 "지우지 않기"와 "지우기"를 함께 정하는 일이라 요건 확인이 먼저입니다.

근거: [보존 정책](https://learn.microsoft.com/purview/retention)

![Purview 보존 정책 화면]({{ "/assets/images/2026/10/m10-3-retention-policies.png" | relative_url }})
*그림 2. Purview > 데이터 수명 주기 관리 > 보존 정책. 목록은 "0 items / No data available"이고, 역할 그룹 권한 안내 배너와 AI 관련 정책 생성에 결제 설정이 필요하다는 안내가 함께 표시됩니다.*

</details>

### 3. DLP 정책

정책은 3건이었습니다(조회). 배포 상태와 적용 워크로드 범위는 확인 불가입니다(아래 목록).

<details markdown="1">
<summary>자세히 보기 (그림 1장)</summary>


- Teams 기본 정책: 우선순위 0, 켜짐
- 기본 DLP 정책: 우선순위 1, "알림과 함께 테스트"
- 디바이스 기본 정책: 우선순위 2, 켜짐

주의할 부분은 테스트 모드 정책이 1건 남아 있다는 점입니다. 아직 실제로 차단하거나 강제하지 않을 수 있습니다. 테스트 모드에서 켜기로 바꿀지는 영향 분석 후 결정할 일입니다.

이 화면은 처음 두 번은 "Loading"에서 멈췄고 세 번째에 열렸습니다. 값이 아니라 도구 문제라 시도 횟수를 기록해 두었습니다([로딩 정체 글]({{ "/m365/troubleshooting/admin-center-loading-stuck/" | relative_url }})).

근거: [DLP 개요](https://learn.microsoft.com/purview/dlp-learn-about-dlp), [Purview 시작하기](https://learn.microsoft.com/purview/purview-where-to-start)

![Purview DLP 정책 목록]({{ "/assets/images/2026/10/m10-1-dlp-policies.png" | relative_url }})
*그림 3. Purview > 데이터 손실 방지 > 정책. 3건이 보인다: Default policy for Teams(우선순위 0, 켜짐), Default DLP policy - Protect sensitive M…(우선순위 1, "Test with notifications"), Default policy for devices(우선순위 2, 켜짐).*

</details>

### 4. 민감도 레이블

레이블은 5개(Personal, Public, General, Confidential, Highly Confidential 계열)이고 작성자는 모두 Microsoft 기본입니다(조회). 화면에 같이 나온 숫자 열의 의미는 확인 불가입니다(아래 목록). 게시 정책 1개는 동기화 완료였고, 개요에 "설정 작업을 볼 권한이 필요하다"는 안내가 있었습니다.

<details markdown="1">
<summary>자세히 보기 (그림 1장)</summary>


기본 레이블 그대로라 주의로 판독했습니다. 자동 레이블 정책과 실제 적용률은 확인 불가입니다(개요에 "설정 작업을 볼 권한이 필요하다"는 안내가 표시됨, 아래 목록). 개선 방안(미실행)은 조직 분류 체계에 맞는 레이블을 설계하고, 기본 공유 링크 동작, 암호화, Teams 연결을 레이블 단위로 정하는 것입니다.

근거: [민감도 레이블](https://learn.microsoft.com/purview/sensitivity-labels), [레이블 만들기](https://learn.microsoft.com/purview/create-sensitivity-labels)

![민감도 레이블 목록]({{ "/assets/images/2026/10/m10-2-sensitivity-labels.png" | relative_url }})
*그림 4. Purview > 정보 보호 > 민감도 레이블. 5개 항목 Personal, Public, General, Confidential, Highly Confidential이 보이고, 작성자는 모두 Microsoft 기본입니다. 위쪽에는 "modern label scheme"으로 이전되었다는 안내가 있습니다.*

</details>

### 5. DSPM for AI

클래식 화면은 정상적으로 열렸고 "시작하기" 4개(Purview 감사 활성화, 브라우저 확장, 디바이스 온보딩, 데이터 검색 확장)가 모두 미완료였습니다(조회). 클래식 DSPM for AI는 메시지 센터 MC1481315 기준 2026-11-30에 종료가 시작되어 2026-12-31까지 완료될 예정이고(문서), 화면에도 새 DSPM으로 이전하라는 안내가 있습니다.

미구성이라 위험으로 판독했습니다. 지금은 Copilot 라이선스가 없어 영향이 작습니다. 다만 4개 중 첫 항목이 감사 활성화라는 점이, **감사 상태 확인이 선행 과제**라는 것을 보여 줍니다.

### 6. Azure Policy

<details markdown="1">
<summary>자세히 보기 (그림 1장)</summary>

- **GUI 경로**: Azure Portal > 정책 > 규정 준수

구독 범위에서 "지정한 범위에 표시할 할당이 없음"이었고, 준수율 100%, 리소스 0, 미준수 정책 0이었습니다(조회).

이 100%는 정상이 아닙니다. **평가 대상이 없어서** 나온 값입니다. 정책과 이니셔티브 할당이 0이니 "통제가 없다"로 읽어야 하고, 리소스가 0이라 준수율 자체도 의미가 없습니다.

개선 방안(미실행)은 허용 지역, 필수 태그, 허용 SKU 같은 기본 정책을 먼저 감사 모드로 할당하고 영향을 본 뒤 강제로 바꾸는 것입니다. 참고로 정책은 RBAC(역할 기반 접근 제어)와 다릅니다. RBAC는 누가 할 수 있는가를, 정책은 어떤 상태여야 하는가를 다룹니다.

근거: [Azure Policy 개요](https://learn.microsoft.com/azure/governance/policy/overview)

![Azure Policy 준수 화면]({{ "/assets/images/2026/10/m10-5-azure-policy.png" | relative_url }})
*그림 5. Azure 포털 > 정책 > 준수. 전체 리소스 준수 100%, 준수/미준수 리소스 0, 미준수 이니셔티브와 정책 0이며 목록에 "지정한 범위에 표시할 할당이 없음"이 나옵니다(정책 할당 0). 구독 이름과 계정은 가렸습니다.*

</details>

### 7. 구독 Owner, UAA, 적격 할당

<details markdown="1">
<summary>자세히 보기 (그림 2장)</summary>

- **GUI 경로**: 구독 > 액세스 제어(IAM) > 역할 할당

구독 역할 할당은 총 2건(한도 5,000 중 2)이고, User Access Administrator 0, 적격(PIM) 0입니다(조회). 소유자 2건은 모두 영구 활성입니다. 하나는 시험 관리자 계정, 다른 하나는 Microsoft 개발자 프로그램이 만든 서비스 사용자입니다.

서비스 사용자는 처음에 이름 일부만 보였습니다. Azure 역할 할당에서 서비스 사용자를 골라 Graph로 상세를 읽어 보니 이름 Microsoft-Developer Program-Sample Data Packs, 유형 Application, 생성 2026-08-23(8/23/2026 7:38:51 PM), 앱 소유 조직은 외부, notes(설명)는 비어 있었습니다. 용도는 확인 불가입니다(아래 목록).

문서의 모범 사례는 구독 소유자를 최대 3명으로 두고 가능하면 적격 할당(PIM)으로 쓰라는 것입니다. 수는 기준 안이지만 **둘 다 상시 권한**이라 주의로 판독했습니다. 용도를 모르니 서비스 사용자를 제거해도 되는지는 판단하지 않았습니다.

개선 방안(미실행)은 업무 계정의 Owner를 적격으로 바꾸고, 서비스 사용자는 용도를 확인한 뒤 범위를 줄이는 것입니다. 역할 할당과 삭제는 이번 실습에서 하지 않는 작업입니다.

근거: [Azure RBAC 모범 사례](https://learn.microsoft.com/azure/role-based-access-control/best-practices), [PIM 연동](https://learn.microsoft.com/azure/role-based-access-control/pim-integration), [PIM 배포 계획](https://learn.microsoft.com/entra/id-governance/privileged-identity-management/pim-deployment-plan)

**실행한 스크립트** (읽기 전용. 토큰을 받아 `$h`(인증 머리글)와 `$B`(Graph 기본 주소)를 정해 둔 상태에서 실행했습니다)

```powershell
$sp = Get-AzRoleAssignment -RoleDefinitionName Owner | Where-Object ObjectType -eq 'ServicePrincipal'
foreach ($a in $sp) {
  Invoke-RestMethod -Headers $h -Uri "$B/servicePrincipals/$($a.ObjectId)?`$select=id,displayName,servicePrincipalType,createdDateTime,notes" |
    Format-List id,displayName,servicePrincipalType,createdDateTime,notes
}
```

![구독 액세스 제어(IAM) 역할 할당]({{ "/assets/images/2026/10/m10-4-sub-iam.png" | relative_url }})
*그림 6. Azure 포털 > 구독 > 액세스 제어(IAM) > 역할 할당. "소유자 (2)"에 사용자 1명과 서비스 사용자 1명이 있고 둘 다 상태 "영구 활성", 범위 "이 리소스"입니다. 구독 이름, 계정, 주체 이름은 가렸습니다.*

![구독 Owner 서비스 사용자 상세]({{ "/assets/images/2026/10/m11-3-service-principal.png" | relative_url }})
*그림 7. 구독 Owner로 등록된 서비스 사용자의 상세(위쪽은 실행한 명령). 이름 Microsoft-Developer Program-Sample Data Packs, 유형 Application, 생성 8/23/2026 7:38:51 PM이 나오고 notes(설명)는 비어 있습니다. ID 줄과 계정 부분은 가렸습니다.*

</details>

### 8. EA/MCA 청구 범위 역할

비용 관리 + 청구의 청구 범위 목록은 "입력한 필터와 일치하는 항목이 없습니다"였습니다(조회). 여러 번 조회해도 0건이었고 접근 권한이 없었습니다.

그래서 측정 불가로 남겼습니다. 개발자 프로그램 구독은 EA/MCA 청구 계정 범위가 보이지 않는 구조로 보이는데, 구조적인 원인은 확인 불가입니다. 다시 재려면 EA/MCA 계정이 있는 운영 테넌트에서 청구 범위의 액세스 제어를 확인해야 합니다. 시도와 막힌 이유는 [청구 범위가 보이지 않음]({{ "/m365/troubleshooting/billing-scope-not-visible/" | relative_url }})에 정리했습니다.

### 9. 이번 실측에서 배운 것

"0건"은 두 가지 뜻일 수 있습니다. 통제가 없다는 뜻(보존, Policy)일 수도 있고, 권한이 없어 안 보인다는 뜻일 수도 있습니다. 배너나 오류 문구를 같이 읽어 구분하고, 구분이 안 되면 시도한 방법과 막힌 이유를 적어 확인 불가로 남깁니다.

100% 같은 좋은 숫자도 모집단이 0이면 의미가 없습니다. 그리고 감사는 다른 점검의 **전제**입니다. 감사 상태를 먼저 확정해야 DSPM이나 규정 준수 점검을 이어갈 수 있습니다.

### 10. 작업 중 막힌 곳

- Cloud Shell에서 Exchange Online 로그인이 AADSTS530035로 막혀 감사 상태를 읽지 못했습니다. 우회하지 않고 내 PC의 브라우저 로그인으로 읽었습니다.
    - 글: [AADSTS530035 트러블슈팅]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }})
- 청구 범위 목록이 비어 EA/MCA 역할을 읽지 못했습니다. 역할을 부여받지 않고 측정 불가로 남겼습니다.
    - 글: [청구 범위 트러블슈팅]({{ "/m365/troubleshooting/billing-scope-not-visible/" | relative_url }})
- DLP 화면이 두 번 "Loading"에서 멈췄고, 세 번째 시도에 열려 값을 읽었습니다.
    - 글: [관리 센터 로딩 정체 트러블슈팅]({{ "/m365/troubleshooting/admin-center-loading-stuck/" | relative_url }})

### 11. 끝내 확인하지 못한 것

<details markdown="1">
<summary>확인 불가 항목 펼쳐 보기 (7건)</summary>

- **보존 정책 0건이 "실제 0개"인지**
    - 시도 방법: 보존 정책 화면과 배너 확인
    - 막힌 이유: 역할 그룹이 제한되어 보이지 않을 수 있다는 배너 문구만으로 구분할 수 없음
    - 다음 방법: 필요한 역할 그룹 권한을 확인한 뒤 같은 화면 재조회
- **DLP 정책 배포 상태, 적용 워크로드 범위**
    - 시도 방법: 정책 목록 읽기
    - 막힌 이유: 정책 상세를 열어 보지 않음
    - 다음 방법: 각 정책 상세를 열어 읽기
- **민감도 레이블의 숫자 열 의미**
    - 시도 방법: 목록 화면 읽기
    - 막힌 이유: 화면만 읽고 의미를 확인하는 단계를 하지 않음
    - 다음 방법: 열 이름과 도움말을 열어 확인
- **자동 레이블 정책과 실제 적용률**
    - 시도 방법: 개요 화면 확인
    - 막힌 이유: 개요에 "설정 작업을 볼 권한이 필요하다"는 안내가 표시됨
    - 다음 방법: 필요한 권한을 확인한 뒤 재조회
- **구독 Owner 서비스 사용자의 용도**
    - 시도 방법: 서비스 사용자 상세 열기
    - 막힌 이유: 설명(notes) 항목이 비어 있음
    - 다음 방법: 계정 소유자에게 확인
- **EA/MCA 청구 범위 역할, 청구 계정 유형**
    - 시도 방법: 비용 관리 + 청구의 청구 범위 조회
    - 막힌 이유: 청구 범위 0건, 접근 권한 없음. 역할을 부여받는 것은 보안 변경이라 하지 않음
    - 다음 방법: 청구 담당자에게 확인, 또는 EA/MCA 계정이 있는 운영 테넌트에서 확인
- **Log Analytics 작업 영역 생성**
    - 시도 방법: (리소스 공급자 등록 상태까지만 읽음)
    - 막힌 이유: 작업 영역 생성은 비용 항목이라 하지 않음
    - 다음 방법: 운영 환경에서 과금 조건을 확인한 뒤 측정

</details>

### 12. 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (7건)</summary>

- 감사 활성화와 상태 확인(문서): [감사 활성화·비활성화](https://learn.microsoft.com/purview/audit-log-enable-disable), [감사 시작하기](https://learn.microsoft.com/purview/audit-get-started), [감사 로그 검색](https://learn.microsoft.com/purview/audit-search), [감사 솔루션 개요](https://learn.microsoft.com/purview/audit-solutions-overview)
- 보존 정책(문서): [보존 정책](https://learn.microsoft.com/purview/retention)
- DLP(문서): [DLP 개요](https://learn.microsoft.com/purview/dlp-learn-about-dlp), [Purview 시작하기](https://learn.microsoft.com/purview/purview-where-to-start)
- 민감도 레이블(문서): [민감도 레이블](https://learn.microsoft.com/purview/sensitivity-labels), [레이블 만들기](https://learn.microsoft.com/purview/create-sensitivity-labels)
- Azure Policy(문서): [Azure Policy 개요](https://learn.microsoft.com/azure/governance/policy/overview)
- 구독 소유자와 PIM(문서): [Azure RBAC 모범 사례](https://learn.microsoft.com/azure/role-based-access-control/best-practices), [PIM 연동](https://learn.microsoft.com/azure/role-based-access-control/pim-integration), [PIM 배포 계획](https://learn.microsoft.com/entra/id-governance/privileged-identity-management/pim-deployment-plan)
- 감사, 보존, DLP, 레이블, DSPM, Policy, IAM, 청구 범위(조회): 위 각 절의 GUI 경로와 그림

</details>
