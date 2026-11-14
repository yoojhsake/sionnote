---
title: "[Azure] 앱 등록과 상황별 최소 권한 검증"
date: 2026-11-14 18:30:00 +0900
categories: [azure]
phase: 운영 자동화
seq: 1
tags: [Azure, 앱 등록, 서비스 주체, 최소 권한, Microsoft Graph, RBAC, Reader, 관리 그룹, Elevate access]
excerpt: "읽기 전용 예시 앱을 등록하고, 하려는 일마다 최소 권한을 문서로 고른 뒤 실제로 줄여 가며 검증했다. 읽기 전용이면 Graph 권한 2개와 Azure Reader 1개로 충분했다"
toc: true
---

스크립트나 자동화 도구가 사람 대신 Azure·M365 정보를 읽게 하려면 앱을 등록하고 권한을 줘야 합니다. 권한은 **Graph 권한**과 **Azure 역할** 두 체계로 따로 줍니다. 읽기 전용 예시 앱 하나로, 상황별 최소 권한을 고르고 실제로 줄여 가며 검증했습니다.

## 요약

- 사람 없이 도는 앱은 기밀 클라이언트로 등록함(리디렉션 URI 없음, 퍼블릭 클라이언트 흐름 사용 안 함)
- Graph는 애플리케이션 권한 + 관리자 동의. 사용자는 User.Read.All, M365 구독은 Organization.Read.All
- Azure 읽기는 Reader 하나로 비용·역할 할당·활동 로그·청구 연결까지 됨. Cost Management 판독기는 불필요(문서·조회)
- 여러 구독을 한 번에 덮으려면 루트 관리 그룹 Reader. 부여하려면 Elevate access를 잠깐 켜야 함
- 중복 역할 2개를 지운 뒤 다시 검증해 실패 0건(조회)

> 근거 표기: 조회 = 이 샌드박스 테넌트에서 직접 읽은 값 · 문서 = Microsoft Learn · 확인 불가 = 시도했지만 확인하지 못한 값(방법·사유 병기) · 추정 = 조회·문서로 직접 확인하지 못한 해석. 예시 앱의 표시 이름("구독 현황관리")은 그림에 그대로 보입니다. 테넌트·구독 이름과 ID, 개체·클라이언트 ID, 계정, 사용자 이름, 메일, 청구 계정 이름은 회색 상자로 가렸고, 클라이언트 암호 값은 어디에도 적지 않았습니다.

---

## 전체 기록

### 1. 권한은 두 체계

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/app-reg-dg-01-two-planes-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/app-reg-dg-01-two-planes.png" | relative_url }}" alt="예시 앱에 Microsoft Graph 애플리케이션 권한 2개와 루트 관리 그룹 Reader를 주는 구조" loading="lazy"></picture>

<details markdown="1">
<summary>등록 전에 정할 네 가지 (표)</summary>

| 정할 것 | 사람 없이 도는 읽기 앱의 선택 | 근거 |
|---|---|---|
| 클라이언트 유형 | 기밀(퍼블릭 클라이언트 흐름 사용 안 함) | 퍼블릭 흐름은 장치 코드·사용자 암호 흐름을 쓰는 앱에서만 켬(문서) |
| Graph 권한 유형 | 애플리케이션 권한 + 관리자 동의 | 위임된 권한은 로그인한 사용자가 있을 때만 쓰임(문서) |
| Azure 권한 범위 | 구독 또는 관리 그룹 | 상위 범위에 준 역할은 하위로 상속(문서) |
| 자격 증명 | 실습은 암호, 운영은 인증서·페더레이션 | 암호보다 인증서가 더 안전하다고 안내(문서) |

</details>

### 2. 상황별 최소 권한

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/app-reg-dg-02-least-privilege-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/app-reg-dg-02-least-privilege.png" | relative_url }}" alt="하려는 일별 최소 권한: Azure는 Reader, Graph는 User.Read.All·Organization.Read.All·LicenseAssignment.Read.All, 청구 계정 전체는 이 테넌트에서 불가" loading="lazy"></picture>

<details markdown="1">
<summary>같은 내용을 표로 보기</summary>

| 하려는 일 | 최소 권한 | 검증 |
|---|---|---|
| 구독·리소스 목록 | Reader | 조회 |
| 여러 구독 한 번에 | 루트 관리 그룹 Reader | 조회 |
| 역할 할당 읽기 | Reader | 조회 |
| 비용 읽기 | Reader | 조회 |
| 활동 로그 | Reader | 조회 |
| 구독의 청구 연결 | Reader | 조회 |
| 청구 계정 전체 | 청구 테넌트의 역할 | 불가능 |
| 사용자 정보 | User.Read.All | 조회 |
| M365 구독 목록 | Organization.Read.All | 조회 |
| 라이선스만 | LicenseAssignment.Read.All | 문서 |

- 부르는 API: Resource Graph·ARM, Management Groups, roleAssignments, Cost Management Query, Activity Log, 구독 billingProperty, Graph `users`·`directory/subscriptions`·`subscribedSkus`
- 피할 넓은 권한: Directory.Read.All, Contributor, Owner, Cost Management 판독기·참가자
- 라이선스만 읽는 경우는 문서 기준이고, 이 글에서는 Organization.Read.All로 함께 검증했습니다(단독 시험 안 함).
- User.Read(위임됨)는 앱 등록 때 기본으로 들어오는 권한이고 앱 단독 실행과는 관계없어 지워도 됩니다(문서). 이 글에서는 남겨 뒀습니다.

</details>

청구 계정 쪽은 [청구 범위가 0건이라 앱에 청구 역할을 줄 수 없을 때]({{ "/azure/troubleshooting/billing-role-scope-zero-other-tenant/" | relative_url }}) 글에 따로 적었습니다.

### 3. 앱 등록

Entra 관리 센터 > 앱 등록 > 새 등록. 단일 테넌트, 리디렉션 URI는 비웁니다(데몬 앱은 필요 없음, 문서).

[![애플리케이션 등록: 예시 앱 이름, 단일 테넌트만, 리디렉션 URI 비움]({{ "/assets/images/2026/11/app-reg-01-new-registration.png" | relative_url }})]({{ "/assets/images/2026/11/app-reg-01-new-registration.png" | relative_url }}){:target="_blank"}

*그림 1. 새 등록(18:36). 리디렉션 URI 플랫폼은 고르지 않습니다.*

[![Authentication 설정: 퍼블릭 클라이언트 흐름 허용 사용 안 함]({{ "/assets/images/2026/11/app-reg-03-public-client-off.png" | relative_url }})]({{ "/assets/images/2026/11/app-reg-03-public-client-off.png" | relative_url }}){:target="_blank"}

*그림 2. Authentication > 설정의 퍼블릭 클라이언트 흐름 허용 "사용 안 함"(기본값)(18:37).*

<details markdown="1">
<summary>등록 직후 개요 화면 (그림 1장)</summary>

[![등록 직후 개요: 클라이언트 ID, 개체 ID, 테넌트 ID]({{ "/assets/images/2026/11/app-reg-02-overview.png" | relative_url }})]({{ "/assets/images/2026/11/app-reg-02-overview.png" | relative_url }}){:target="_blank"}

*그림 3. 개요. 실행에 쓰는 값은 클라이언트 ID와 테넌트 ID(가림).*

</details>

### 4. Graph 애플리케이션 권한과 관리자 동의

API 사용 권한 > 권한 추가 > Microsoft Graph > **애플리케이션 사용 권한**.

[![애플리케이션 사용 권한에서 Organization.Read.All 선택]({{ "/assets/images/2026/11/app-reg-04-graph-app-permission.png" | relative_url }})]({{ "/assets/images/2026/11/app-reg-04-graph-app-permission.png" | relative_url }}){:target="_blank"}

*그림 4. Organization.Read.All(18:38). User.Read.All도 같은 방법으로 추가합니다.*

[![관리자 동의 후 세 권한 모두 허용됨]({{ "/assets/images/2026/11/app-reg-07-admin-consent-granted.png" | relative_url }})]({{ "/assets/images/2026/11/app-reg-07-admin-consent-granted.png" | relative_url }}){:target="_blank"}

*그림 5. "관리자 동의 허용" 뒤 세 권한 모두 허용됨(18:57). 동의 전에는 효력이 없습니다.*

<details markdown="1">
<summary>User.Read.All 추가와 동의 확인 창 (그림 2장)</summary>

[![User.Read.All 선택]({{ "/assets/images/2026/11/app-reg-05-user-read-all.png" | relative_url }})]({{ "/assets/images/2026/11/app-reg-05-user-read-all.png" | relative_url }}){:target="_blank"}

*그림 6. User.Read.All 추가(18:57).*

[![관리자 동의 확인 창]({{ "/assets/images/2026/11/app-reg-06-admin-consent-confirm.png" | relative_url }})]({{ "/assets/images/2026/11/app-reg-06-admin-consent-confirm.png" | relative_url }}){:target="_blank"}

*그림 7. 관리자 동의 확인 창(18:57).*

</details>

### 5. 클라이언트 암호

인증서 및 암호 > 새 클라이언트 암호. 값은 만든 직후 한 번만 보입니다(문서).

[![클라이언트 암호 생성 후: 만료 2027-05-13, 값은 가림]({{ "/assets/images/2026/11/app-reg-09-secret-created.png" | relative_url }})]({{ "/assets/images/2026/11/app-reg-09-secret-created.png" | relative_url }}){:target="_blank"}

*그림 8. 만료 2027-05-13(권장 180일)(18:43). 값과 비밀 ID는 가렸습니다.*

<details markdown="1">
<summary>암호 추가 패널 (그림 1장)</summary>

[![클라이언트 암호 추가: 설명, 만료 권장 180일]({{ "/assets/images/2026/11/app-reg-08-secret-add.png" | relative_url }})]({{ "/assets/images/2026/11/app-reg-08-secret-add.png" | relative_url }}){:target="_blank"}

*그림 9. 설명과 만료(권장 180일).*

</details>

### 6. Azure 역할: 구독에서 루트 관리 그룹으로

구독 IAM > 역할 할당 추가 > **독자(Reader)** > 구성원에 앱을 넣습니다.

[![구독 IAM 역할 할당 목록: 독자 1(예시 앱)]({{ "/assets/images/2026/11/app-reg-11-sub-iam-assigned.png" | relative_url }})]({{ "/assets/images/2026/11/app-reg-11-sub-iam-assigned.png" | relative_url }}){:target="_blank"}

*그림 10. 구독 범위 Reader 할당(18:47).*

<details markdown="1">
<summary>검토 + 할당 화면 (그림 1장)</summary>

[![구독 범위 독자 역할 할당 검토]({{ "/assets/images/2026/11/app-reg-10-sub-reader-review.png" | relative_url }})]({{ "/assets/images/2026/11/app-reg-10-sub-reader-review.png" | relative_url }}){:target="_blank"}

*그림 11. 범위는 구독, 구성원 유형은 "앱".*

</details>

여러 구독을 한 번에 덮으려면 루트 관리 그룹에 줍니다. 전역 관리자도 루트 권한은 자동으로 없어서(그림 12), Entra > 속성 > **Azure 리소스에 대한 액세스 관리**를 "예"로 저장합니다(Elevate access, 문서).

[![관리 그룹 화면: 루트 관리 그룹 권한이 없다는 안내]({{ "/assets/images/2026/11/app-reg-12-mg-no-access.png" | relative_url }})]({{ "/assets/images/2026/11/app-reg-12-mg-no-access.png" | relative_url }}){:target="_blank"}

*그림 12. 관리 그룹 개요의 "루트 관리 그룹에 액세스하는 데 필요한 권한이 없습니다" 안내(18:58).*

[![Azure 리소스에 대한 액세스 관리 토글 예]({{ "/assets/images/2026/11/app-reg-13-elevate-on.png" | relative_url }})]({{ "/assets/images/2026/11/app-reg-13-elevate-on.png" | relative_url }}){:target="_blank"}

*그림 13. 토글 "예"(18:58). 켠 사람에게 루트 범위 User Access Administrator가 붙습니다.*

[![루트 관리 그룹 독자 할당 검토: 범위 managementGroups]({{ "/assets/images/2026/11/app-reg-16-root-reader-review.png" | relative_url }})]({{ "/assets/images/2026/11/app-reg-16-root-reader-review.png" | relative_url }}){:target="_blank"}

*그림 14. 루트 관리 그룹 IAM에서 앱에 독자 할당(19:00). 범위가 `managementGroups/<테넌트 ID>`입니다.*

<details markdown="1">
<summary>루트 IAM 배너, 역할 선택, 처음에 함께 줬던 Cost Management 판독기 (그림 4장)</summary>

[![루트 관리 그룹 IAM: 조치 필요 배너와 User Access Administrator]({{ "/assets/images/2026/11/app-reg-14-root-iam-uaa.png" | relative_url }})]({{ "/assets/images/2026/11/app-reg-14-root-iam-uaa.png" | relative_url }}){:target="_blank"}

*그림 15. "조치 필요" 배너와 관리자 본인의 User Access Administrator(18:59).*

[![역할 할당 추가: 독자 선택]({{ "/assets/images/2026/11/app-reg-15-root-reader-select.png" | relative_url }})]({{ "/assets/images/2026/11/app-reg-15-root-reader-select.png" | relative_url }}){:target="_blank"}

*그림 16. 역할 > 독자(18:59).*

[![Cost Management 판독기 선택]({{ "/assets/images/2026/11/app-reg-17-cost-reader-select.png" | relative_url }})]({{ "/assets/images/2026/11/app-reg-17-cost-reader-select.png" | relative_url }}){:target="_blank"}

*그림 17. Cost Management 판독기(19:01). 7절에서 지운 역할입니다.*

[![루트 관리 그룹 역할 할당 3건]({{ "/assets/images/2026/11/app-reg-18-root-assignments.png" | relative_url }})]({{ "/assets/images/2026/11/app-reg-18-root-assignments.png" | relative_url }}){:target="_blank"}

*그림 18. 앱의 독자·Cost Management 판독기, 관리자의 User Access Administrator(19:02).*

</details>

작업이 끝나면 Elevate access를 끄고 꺼졌는지 확인합니다. 이번에는 끄기가 저장되지 않아 루트 권한이 남은 일이 있었습니다([별도 글]({{ "/azure/troubleshooting/elevate-off-not-saved-root-uaa-left/" | relative_url }})).

### 7. 권한 줄이기

첫 검증(22:04) 때 앱의 Azure 역할은 3개였습니다. 문서로 보니 2개는 중복이었습니다.

- Cost Management 판독기: Reader에 비용 조회(Query)가 이미 포함(문서). MCA 구독은 관리 그룹 범위 비용 기능도 지원하지 않음(문서)
- 구독 Reader: 루트에서 상속된 Reader와 같음

[![정리 전 구독 IAM: 독자 2, Cost Management 판독기 1]({{ "/assets/images/2026/11/app-reg-19-sub-iam-before-cleanup.png" | relative_url }})]({{ "/assets/images/2026/11/app-reg-19-sub-iam-before-cleanup.png" | relative_url }}){:target="_blank"}

*그림 19. 정리 전(23:17). 예시 앱이 독자 2건(이 리소스·상속)과 Cost Management 판독기 1건(상속).*

[![최종 구독 IAM: 독자 1(관리 그룹 상속됨)]({{ "/assets/images/2026/11/app-reg-22-sub-iam-final.png" | relative_url }})]({{ "/assets/images/2026/11/app-reg-22-sub-iam-final.png" | relative_url }}){:target="_blank"}

*그림 20. 정리 후(23:31). 예시 앱은 상속된 독자 1건뿐입니다.*

<details markdown="1">
<summary>지운 과정 (그림 2장)</summary>

[![역할 할당 제거 확인 창]({{ "/assets/images/2026/11/app-reg-20-sub-reader-remove-confirm.png" | relative_url }})]({{ "/assets/images/2026/11/app-reg-20-sub-reader-remove-confirm.png" | relative_url }}){:target="_blank"}

*그림 21. 구독 IAM에서 "이 리소스" 범위 독자 한 행만 골라 삭제(23:18). 상속된 행은 여기서 지울 수 없습니다.*

[![루트 관리 그룹 IAM: Cost Management 판독기 삭제 후]({{ "/assets/images/2026/11/app-reg-21-root-iam-cost-removed.png" | relative_url }})]({{ "/assets/images/2026/11/app-reg-21-root-iam-cost-removed.png" | relative_url }}){:target="_blank"}

*그림 22. Elevate access를 잠깐 켜고 루트 IAM에서 Cost Management 판독기 삭제(23:21).*

</details>

### 8. 줄인 권한으로 다시 검증

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/app-reg-dg-03-verify-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/app-reg-dg-03-verify.png" | relative_url }}" alt="정리 전 Azure 역할 3개, 정리 후 1개, 호출 9종 성공 실패 0건" loading="lazy"></picture>

<details markdown="1">
<summary>호출별 결과 표</summary>

| 호출 | 필요한 권한 | 정리 전 → 후 |
|---|---|---|
| 구독 목록 | Reader | 성공 → 성공 |
| 관리 그룹 하위 구독 | 관리 그룹 Reader | 성공 → 성공 |
| 역할 할당 | Reader | 성공 → 성공 |
| 비용 | Reader | 성공 → 성공 |
| 활동 로그 | Reader | 성공 → 성공 |
| 청구 연결 | Reader | 성공 → 성공 |
| Graph 사용자 | User.Read.All | 성공 → 성공 |
| Graph M365 구독 | Organization.Read.All | 호출 안 함 → 성공 |
| Graph 라이선스 | Organization.Read.All | 호출 안 함 → 성공 |

정리 전은 22:04, 정리 후는 23:33 검증입니다. 비용은 두 번 모두 구독 범위로 읽혔습니다. 정리 후 검증의 활동 로그 마지막 작업이 23:18 "Delete role assignment"(그림 21)로 잡혀, 정리 뒤 권한으로 돈 것도 확인됩니다(조회).

</details>

### 9. 운영 판단

- 암호는 2027-05-13 만료. 운영이면 인증서·페더레이션 자격 증명으로(문서)
- 루트 역할 승인이 어려운 환경은 구독 Reader로 시작. 구독이 늘 때마다 다시 부여
- Elevate access는 작업할 때만 켜고, 끈 뒤 새로 불러온 토글·루트 UAA 0건·감사 로그로 확인
- 권한을 더하기 전에 문서의 역할·권한 표부터 확인

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (8건)</summary>

- **문서**: Graph 최소 권한 — [List subscriptions](https://learn.microsoft.com/graph/api/directory-list-subscriptions), [List subscribedSkus](https://learn.microsoft.com/graph/api/subscribedsku-list), [Get a user](https://learn.microsoft.com/graph/api/user-get)
- **문서**: 퍼블릭/기밀 클라이언트, 위임·애플리케이션 권한, 인증서 권장 — [Public client and confidential client applications](https://learn.microsoft.com/entra/identity-platform/msal-client-applications), [Application configuration options](https://learn.microsoft.com/entra/identity-platform/msal-client-application-configuration)
- **문서**: Reader의 비용 조회, MCA의 관리 그룹 비용 미지원, 관리 그룹 상속 — [Understand and work with scopes](https://learn.microsoft.com/azure/cost-management-billing/costs/understand-work-scopes)
- **문서**: Elevate access — [Elevate access to manage all Azure subscriptions and management groups](https://learn.microsoft.com/azure/role-based-access-control/elevate-access-global-admin)
- **조회**: 앱 등록 설정, Graph 권한 허용, 암호 만료 — 그림 1~9
- **조회**: 구독·루트 관리 그룹 역할 할당 정리 전후 — 그림 10~22
- **조회**: 정리 전(22:04)·후(23:33) 호출별 결과, 실패 0건 — 8절
- **조회**: 정리 후 활동 로그 마지막 작업 23:18 — 8절

</details>
