---
title: "[M365·Azure] 실측 — Purview 규정 준수·Azure 거버넌스: 감사, 보존, DLP, 레이블, Policy, 구독 권한 (전체 기록)"
date: 2026-10-22 13:00:00 +0900
categories: [m365]
phase: 운영 설정 실측
seq: 5
tags: [M365·Azure, 실측, Purview, 감사, DLP, 민감도 레이블, Azure Policy, 전체 기록]
excerpt: "감사 로그·보존·DLP·민감도 레이블과 Azure Policy·구독 소유자 권한을 바꾸지 않고 읽어 판독한 결과, 측정 불가 사유, 개선 방안(미실행) 전체 기록"
---

측정은 2026-10-22(목)부터 2026-10-23(금)까지 했고 **모든 측정은 읽기 전용**입니다. 시작·평가판·저장 버튼은 누르지 않았습니다. 방법은 [측정 방법 글]({{ "/m365/measurement-method/" | relative_url }})에 있습니다.

> 근거 표기: **조회** = 화면에서 직접 읽음 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못함(시도 방법·막힌 이유·다음 방법 병기). 테넌트 ID, 구독 ID, 도메인은 게시하지 않았습니다. 개선 방안은 권고이며 **이번에 실행하지 않았습니다.**

## 요약

| 영역 | 읽은 값(조회) | 판독 |
|---|---|---|
| 통합 감사 로그 | 감사 검색 화면에 "활동이 기록되고 있는지 확인하는 데 문제가 있다" 오류와 "사용자 및 관리자 활동 기록 시작" 버튼. 내 PC PowerShell로 읽은 수집 상태는 꺼짐(False) | 화면만으로는 측정 불가, PowerShell 값으로 꺼짐 확인 |
| 보존 정책 | 0건, 보존 레이블 없음 | 위험 |
| DLP 정책 | 3건(Teams 기본 정책 켜짐, 기본 DLP 정책 1건은 "알림과 함께 테스트", 디바이스 기본 정책 켜짐) | 주의 |
| 민감도 레이블 | 5개(Microsoft 기본), 게시 정책 1개 동기화 완료 | 주의 |
| DSPM for AI | "시작하기" 4개 항목 모두 미완료. 클래식 화면은 2026-11-30부터 종료 시작(12-31까지 완료 예정) | 위험 |
| Azure Policy | 정책·이니셔티브 **할당 0**, 준수율 100%(리소스 0) | 주의(통제 없음) |
| 구독 Owner | 2건 모두 영구 활성(사용자 1, 서비스 사용자 1), User Access Administrator 0, 적격 0 | 주의 |
| EA/MCA 청구 범위 역할 | 청구 범위 0건 | 측정 불가 |

끝내 읽지 못한 항목은 글 끝의 "끝내 확인하지 못한 것" 표에 시도 방법·막힌 이유·다음 방법을 적었습니다.

## 작업 중 막힌 곳

| 상황 | 한 줄 대처 | 글 |
|---|---|---|
| Cloud Shell에서 Exchange Online 로그인이 AADSTS530035로 막혀 감사 상태를 못 읽음 | 우회하지 않고 내 PC의 브라우저 로그인으로 읽음 | [AADSTS530035 트러블슈팅]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }}) |
| 감사 로그를 켜는 명령이 서버 오류로 거부됨 | 4회 시도 후 멈추고 지원 요청·대체 근거를 다음 방법으로 남김 | [감사 로그 켜기 거부 트러블슈팅]({{ "/m365/troubleshooting/audit-log-enable-rejected/" | relative_url }}) |
| 청구 범위 목록이 비어 EA/MCA 역할을 못 읽음 | 역할을 부여받지 않고 측정 불가로 남김 | [청구 범위 트러블슈팅]({{ "/m365/troubleshooting/billing-scope-not-visible/" | relative_url }}) |
| DLP 화면이 두 번 "Loading"에서 멈춤 | 세 번째 시도에 열려 값을 읽음 | [관리 센터 로딩 정체 트러블슈팅]({{ "/m365/troubleshooting/admin-center-loading-stuck/" | relative_url }}) |

---

## 전체 기록

### 1. 통합 감사 로그

- **GUI 경로**: Microsoft Purview 포털 > 감사 > 검색
- **조회(화면)**: 검색 폼이 회색으로 비활성이고, "활동이 기록되고 있는지 확인하는 데 문제가 있다"는 문구와 함께 **"사용자 및 관리자 활동 기록 시작" 버튼**이 보였습니다. 같은 화면을 다시 열어도 같은 문구가 그대로이고 검색 버튼은 회색이어서, 이 화면만으로는 "기록 중인지"를 알 수 없었습니다. 이 버튼은 설정을 바꾸는 동작이라 누르지 않았습니다.
- **시도 → 막힘 → 다른 방법 → 결과**:
  1. 시도: 오류 문구만으로는 감사가 꺼져 있다고 확정할 수 없습니다. 문서에 따르면 감사가 켜져 있는지는 Exchange Online PowerShell(`UnifiedAuditLogIngestionEnabled`)로 확인합니다.
  2. 막힘: Cloud Shell에서 Exchange Online 로그인이 막혔습니다([AADSTS530035 글]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }})).
  3. 다른 방법: 내 PC의 PowerShell에서 브라우저 로그인으로 `Get-AdminAuditLogConfig`의 감사 수집 항목을 읽었습니다.
  4. 결과: 수집 상태는 **꺼짐(False)** 이었습니다(10/26, 조회). 켜는 명령은 서버 오류로 거부됐습니다. 과정과 대처는 [감사 로그를 켜는 명령이 거부됨]({{ "/m365/troubleshooting/audit-log-enable-rejected/" | relative_url }})에 정리했습니다.
- **판독**: 화면만으로는 측정 불가였고, PowerShell 값으로 수집이 꺼져 있음을 확인했습니다. 문서에 따르면 감사를 켠 직후에는 반영까지 최대 60분이 걸립니다.
- **왜 중요한가**: 감사가 꺼져 있으면 사고가 나도 "누가 무엇을 했는지" 찾을 수 없습니다. 반대로 Entra 감사 로그는 별도로 있어, Identity 실측 글에서 Elevate access 기록을 확인할 수 있었습니다.
- 근거: [감사 활성화·비활성화](https://learn.microsoft.com/purview/audit-log-enable-disable), [감사 시작하기](https://learn.microsoft.com/purview/audit-get-started), [감사 로그 검색](https://learn.microsoft.com/purview/audit-search), [감사 솔루션 개요](https://learn.microsoft.com/purview/audit-solutions-overview) (감사 Standard 보관 180일은 문서 설명)

![Purview 감사 검색 화면]({{ "/assets/images/2026/10/m10-audit-retry.png" | relative_url }})
*그림 1. Purview 감사 검색 화면. "활동을 기록 중인지 파악하는 데 문제가 있습니다" 문구와 "사용자 및 관리자 활동 기록 시작" 버튼이 있고, 날짜 범위 입력란이 보인다.*

### 2. 보존 정책

- **GUI 경로**: Purview > 데이터 수명 주기 관리 > 보존 정책
- **조회**: "0 items / No data available", 개요에는 "No retention labels detected". 역할 그룹이 제한되어 보이지 않을 수 있다는 배너가 있었습니다.
- **판독 — 위험**: Teams·SharePoint·Exchange 어디에도 보존 정책이 없습니다. 배너 때문에 "실제로 0개"인지 "권한이 없어 안 보이는 것"인지는 확정하지 못했습니다(권한 영향 **확인 불가**, 아래 표). 그래도 화면 값 기준으로는 위험으로 읽습니다.
- **개선 방안(미실행)**: 법적·업무 요건에 맞춰 Teams 채팅·채널 메시지, Exchange, SharePoint/OneDrive 보존 정책을 설계합니다. 보존은 "지우지 않기"와 "지우기"를 함께 정하는 일이라 요건 확인이 먼저입니다.
- 근거: [보존 정책](https://learn.microsoft.com/purview/retention)

![Purview 보존 정책 화면]({{ "/assets/images/2026/10/m10-3-retention-policies.png" | relative_url }})
*그림 2. Purview > 데이터 수명 주기 관리 > 보존 정책. 목록은 "0 items / No data available"이고, 역할 그룹 권한 안내 배너와 AI 관련 정책 생성에 결제 설정이 필요하다는 안내가 함께 표시된다.*

### 3. DLP 정책

- **조회**: 정책 3건. Teams 기본 정책(우선순위 0, 켜짐), 기본 DLP 정책(우선순위 1, "알림과 함께 테스트"), 디바이스 기본 정책(우선순위 2, 켜짐). 배포 상태와 적용 워크로드 범위는 **확인 불가**입니다(아래 표).
- **판독 — 주의**: 테스트 모드 정책이 1건 남아 있어 아직 실제로 차단·강제하지 않을 수 있습니다. 테스트 모드에서 켜기로 전환할지는 영향 분석 후 결정할 일입니다.
- **화면 정체**: 이 화면은 첫 두 번의 시도에서 "Loading"에서 멈췄고 세 번째에 열렸습니다. 값이 아닌 도구 문제이므로 시도 횟수를 기록했습니다([로딩 정체 글]({{ "/m365/troubleshooting/admin-center-loading-stuck/" | relative_url }})).
- 근거: [DLP 개요](https://learn.microsoft.com/purview/dlp-learn-about-dlp), [Purview 시작하기](https://learn.microsoft.com/purview/purview-where-to-start)

![Purview DLP 정책 목록]({{ "/assets/images/2026/10/m10-1-dlp-policies.png" | relative_url }})
*그림 3. Purview > 데이터 손실 방지 > 정책. 3건이 보인다: Default policy for Teams(우선순위 0, 켜짐), Default DLP policy - Protect sensitive M…(우선순위 1, "Test with notifications"), Default policy for devices(우선순위 2, 켜짐).*

### 4. 민감도 레이블

- **조회**: 레이블 5개(Personal, Public, General, Confidential, Highly Confidential 계열), 작성자는 모두 Microsoft 기본. 화면에 함께 표시된 숫자 열의 의미는 **확인 불가**입니다(아래 표). 게시 정책 1개가 동기화 완료. 개요에 "설정 작업을 볼 권한이 필요하다"는 안내.
- **판독 — 주의**: 기본 레이블 그대로이며, 자동 레이블 정책과 실제 적용률은 **확인 불가**입니다(개요에 "설정 작업을 볼 권한이 필요하다"는 안내가 표시됨, 아래 표).
- **개선 방안(미실행)**: 조직 분류 체계에 맞는 레이블을 설계하고 기본 공유 링크 동작·암호화·Teams 연결을 레이블 단위로 정합니다.
- 근거: [민감도 레이블](https://learn.microsoft.com/purview/sensitivity-labels), [레이블 만들기](https://learn.microsoft.com/purview/create-sensitivity-labels)

![민감도 레이블 목록]({{ "/assets/images/2026/10/m10-2-sensitivity-labels.png" | relative_url }})
*그림 4. Purview > 정보 보호 > 민감도 레이블. 5개 항목 Personal, Public, General, Confidential, Highly Confidential이 보이고, 작성자는 모두 Microsoft 기본이다. 위쪽에는 "modern label scheme"으로 이전되었다는 안내가 있다.*

### 5. DSPM for AI

- **조회**: 클래식 화면은 정상적으로 열렸고 "시작하기" 4개(Purview 감사 활성화, 브라우저 확장, 디바이스 온보딩, 데이터 검색 확장)가 모두 미완료. 클래식 DSPM for AI는 메시지 센터 MC1481315 기준 2026-11-30에 종료가 시작되어 2026-12-31까지 완료될 예정이며(문서), 화면에도 새 DSPM으로 이전하라는 안내가 있습니다.
- **판독 — 위험(미구성)**: Copilot 라이선스가 없는 현재는 영향이 작지만, 4개 중 첫 항목이 감사 활성화라는 점에서 **감사 상태 확인이 선행 과제**임을 보여 줍니다.

### 6. Azure Policy

- **GUI 경로**: Azure Portal > 정책 > 규정 준수
- **조회**: 구독 범위에서 "지정한 범위에 표시할 할당이 없음". 준수율 100%, 리소스 0, 미준수 정책 0.
- **판독 — 주의(정상 아님)**: 100%라는 숫자는 **평가 대상이 없어서** 나온 값입니다. 할당이 0이므로 "통제가 없다"로 읽어야 합니다. 리소스가 0이라 준수율 자체도 의미가 없습니다.
- **개선 방안(미실행)**: 허용 지역·필수 태그·허용 SKU 같은 기본 정책을 먼저 감사 모드로 할당하고, 영향을 본 뒤 강제로 전환합니다. 정책은 RBAC와 다릅니다. RBAC는 **누가 할 수 있는가**, 정책은 **어떤 상태여야 하는가**를 다룹니다.
- 근거: [Azure Policy 개요](https://learn.microsoft.com/azure/governance/policy/overview)

![Azure Policy 준수 화면]({{ "/assets/images/2026/10/m10-5-azure-policy.png" | relative_url }})
*그림 5. Azure 포털 > 정책 > 준수. 전체 리소스 준수 100%, 준수/미준수 리소스 0, 미준수 이니셔티브·정책 0이며 목록에 "지정한 범위에 표시할 할당이 없음"이 나온다(정책 할당 0). 구독 이름과 계정은 가렸다.*

### 7. 구독 Owner·UAA·적격 할당

- **GUI 경로**: 구독 > 액세스 제어(IAM) > 역할 할당
- **조회**: 구독 역할 할당 총 2건(한도 5,000 중 2). 소유자 2건은 모두 영구 활성이며, 하나는 시험 관리자 계정, 다른 하나는 Microsoft 개발자 프로그램이 만든 서비스 사용자입니다. User Access Administrator 0, 적격(PIM) 0.
- **서비스 사용자 상세**: 처음에는 이름 일부만 보였습니다. Azure 역할 할당에서 서비스 사용자를 골라 Graph로 상세를 읽자 이름 Microsoft-Developer Program-Sample Data Packs, 유형 Application, 생성 2026-08-23(8/23/2026 7:38:51 PM), 앱 소유 조직은 외부로 나왔고 notes(설명)는 비어 있었습니다. 용도는 **확인 불가**입니다(아래 표).
- **판독 — 주의**: 문서의 모범 사례는 구독 소유자를 최대 3명으로 두고 가능하면 적격 할당(PIM)으로 쓰라는 것입니다. 수는 기준 안이지만 **둘 다 상시 권한**입니다. 용도를 모르므로 서비스 사용자의 제거 가능 여부는 판단하지 않았습니다.
- **개선 방안(미실행)**: 업무 계정의 Owner를 적격으로 전환하고, 서비스 사용자는 용도 확인 후 범위를 줄입니다. 역할 할당과 삭제는 이번 실습에서 하지 않는 작업입니다.
- 근거: [Azure RBAC 모범 사례](https://learn.microsoft.com/azure/role-based-access-control/best-practices), [PIM 연동](https://learn.microsoft.com/azure/role-based-access-control/pim-integration), [PIM 배포 계획](https://learn.microsoft.com/entra/id-governance/privileged-identity-management/pim-deployment-plan)

**실행한 스크립트** (읽기 전용. 토큰을 받아 `$h`(인증 머리글)와 `$B`(Graph 기본 주소)를 정해 둔 상태에서 실행했습니다)

```powershell
$sp = Get-AzRoleAssignment -RoleDefinitionName Owner | Where-Object ObjectType -eq 'ServicePrincipal'
foreach ($a in $sp) {
  Invoke-RestMethod -Headers $h -Uri "$B/servicePrincipals/$($a.ObjectId)?`$select=id,displayName,servicePrincipalType,createdDateTime,notes" |
    Format-List id,displayName,servicePrincipalType,createdDateTime,notes
}
```

![구독 액세스 제어(IAM) 역할 할당]({{ "/assets/images/2026/10/m10-4-sub-iam.png" | relative_url }})
*그림 6. Azure 포털 > 구독 > 액세스 제어(IAM) > 역할 할당. "소유자 (2)"에 사용자 1명과 서비스 사용자 1명이 있고 둘 다 상태 "영구 활성", 범위 "이 리소스"이다. 구독 이름·계정·주체 이름은 가렸다.*

![구독 Owner 서비스 사용자 상세]({{ "/assets/images/2026/10/m11-3-service-principal.png" | relative_url }})
*그림 7. 구독 Owner로 등록된 서비스 사용자의 상세(위쪽은 실행한 명령). 이름 Microsoft-Developer Program-Sample Data Packs, 유형 Application, 생성 8/23/2026 7:38:51 PM이 나오고 notes(설명)는 비어 있다. ID 줄과 계정 부분은 가렸다.*

### 8. EA/MCA 청구 범위 역할

- **조회**: 비용 관리 + 청구의 청구 범위 목록이 "입력한 필터와 일치하는 항목이 없습니다". 청구 범위는 여러 번 조회해도 0건이었고 접근 권한이 없었습니다.
- **판독 — 측정 불가**: 개발자 프로그램 구독은 EA/MCA 청구 계정 범위가 보이지 않는 구조로 보입니다. 구조 원인은 **확인 불가**입니다.
- **재측정 방법**: EA/MCA 계정이 있는 운영 테넌트에서 청구 범위의 액세스 제어를 확인합니다. 시도와 막힌 이유는 [청구 범위가 보이지 않음]({{ "/m365/troubleshooting/billing-scope-not-visible/" | relative_url }})에 정리했습니다.

### 9. 끝내 확인하지 못한 것 (시도 방법 · 막힌 이유 · 다음 방법)

| 항목 | 시도 방법 | 막힌 이유 | 다음 방법 |
|---|---|---|---|
| 감사 로그 켜기 | `Set-AdminAuditLogConfig` 4회(내 PC PowerShell) | 서버 오류로 거부(조직 상태 오류, 권한 오류가 아님). 역할을 올리거나 보안 설정을 바꾸는 방향으로는 가지 않음 | 시간을 두고 재시도, 계속되면 지원 요청([감사 로그 켜기 거부 글]({{ "/m365/troubleshooting/audit-log-enable-rejected/" | relative_url }})) |
| 보존 정책 0건이 "실제 0개"인지 | 보존 정책 화면과 배너 확인 | 역할 그룹이 제한되어 보이지 않을 수 있다는 배너 문구만으로 구분할 수 없음 | 필요한 역할 그룹 권한을 확인한 뒤 같은 화면 재조회 |
| DLP 정책 배포 상태·적용 워크로드 범위 | 정책 목록 읽기 | 정책 상세를 열어 보지 않음 | 각 정책 상세를 열어 읽기 |
| 민감도 레이블의 숫자 열 의미 | 목록 화면 읽기 | 화면만 읽고 의미를 확인하는 단계를 하지 않음 | 열 이름·도움말을 열어 확인 |
| 자동 레이블 정책과 실제 적용률 | 개요 화면 확인 | 개요에 "설정 작업을 볼 권한이 필요하다"는 안내가 표시됨 | 필요한 권한을 확인한 뒤 재조회 |
| 구독 Owner 서비스 사용자의 용도 | 서비스 사용자 상세 열기 | 설명(notes) 항목이 비어 있음 | 계정 소유자에게 확인 |
| EA/MCA 청구 범위 역할, 청구 계정 유형 | 비용 관리 + 청구의 청구 범위 조회 | 청구 범위 0건, 접근 권한 없음. 역할을 부여받는 것은 보안 변경이라 하지 않음 | 청구 담당자에게 확인, 또는 EA/MCA 계정이 있는 운영 테넌트에서 확인 |
| Log Analytics 작업 영역 생성 | (리소스 공급자 등록 상태까지만 읽음) | 작업 영역 생성은 비용 항목이라 하지 않음 | 운영 환경에서 과금 조건을 확인한 뒤 측정 |

### 10. 배운 점

- **"0건"이 두 가지 뜻**일 수 있습니다. 통제가 없다(보존, Policy)는 뜻과 권한이 없어 안 보인다는 뜻입니다. 배너나 오류 문구를 같이 읽어 구분하고, 구분이 안 되면 시도한 방법과 막힌 이유를 적고 확인 불가로 남깁니다.
- 100% 같은 좋은 숫자도 모집단이 0이면 의미가 없습니다.
- 감사는 다른 점검의 **전제**입니다. 감사 상태를 먼저 확정해야 이후 DSPM, 규정 준수 점검을 이어갈 수 있습니다.

### 11. 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 문서 | 감사 활성화·상태 확인 | [감사 활성화·비활성화](https://learn.microsoft.com/purview/audit-log-enable-disable), [감사 시작하기](https://learn.microsoft.com/purview/audit-get-started), [감사 로그 검색](https://learn.microsoft.com/purview/audit-search), [감사 솔루션 개요](https://learn.microsoft.com/purview/audit-solutions-overview) |
| 문서 | 보존 정책 | [보존 정책](https://learn.microsoft.com/purview/retention) |
| 문서 | DLP | [DLP 개요](https://learn.microsoft.com/purview/dlp-learn-about-dlp), [Purview 시작하기](https://learn.microsoft.com/purview/purview-where-to-start) |
| 문서 | 민감도 레이블 | [민감도 레이블](https://learn.microsoft.com/purview/sensitivity-labels), [레이블 만들기](https://learn.microsoft.com/purview/create-sensitivity-labels) |
| 문서 | Azure Policy | [Azure Policy 개요](https://learn.microsoft.com/azure/governance/policy/overview) |
| 문서 | 구독 소유자·PIM | [Azure RBAC 모범 사례](https://learn.microsoft.com/azure/role-based-access-control/best-practices), [PIM 연동](https://learn.microsoft.com/azure/role-based-access-control/pim-integration), [PIM 배포 계획](https://learn.microsoft.com/entra/id-governance/privileged-identity-management/pim-deployment-plan) |
| 조회 | 감사·보존·DLP·레이블·DSPM·Policy·IAM·청구 범위 | 위 각 절의 GUI 경로와 그림 |
