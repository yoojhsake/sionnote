---
title: "[Troubleshooting] 청구 범위가 0건이라 앱에 청구 역할을 줄 수 없을 때"
date: 2026-11-14 23:45:00 +0900
categories: [azure, troubleshooting]
area: 보고서·감사·청구
seq: 1
tags: [Troubleshooting, Azure, 청구 범위, MCA, billingProperty, 청구 속성, 서비스 주체]
excerpt: "앱에 청구 읽기 역할을 주려 했지만 이 디렉터리의 청구 범위는 0건이었다. 구독의 청구 속성으로 보니 MCA 청구 계정이 다른 테넌트에 있었고, 구독 단위 청구 연결은 Reader만으로 읽혔다"
toc: true
---

앱에 청구 정보를 읽는 역할을 주려고 비용 관리 + 청구를 열었더니 청구 범위가 하나도 없었습니다. 역할을 줄 범위 자체가 없는 것입니다. 구독의 **청구 속성**을 열어 보니 청구 계정·청구 프로필·청구서 섹션은 분명히 있었고, 앱으로 읽은 청구 연결 정보에서 그 청구 계정이 **다른 테넌트**에 있다는 것이 나왔습니다.

## 요약

- 이 디렉터리의 청구 범위가 0건이면 MCA 청구 역할을 줄 곳이 없음. 앱에 청구 역할을 주는 것은 이 디렉터리에서는 불가능
- 구독이 어느 청구 계정에 붙어 있는지는 구독 > 설정 > 청구 속성에서 보이고, 앱은 Azure Reader만으로 같은 정보(billingProperty)를 읽었음(조회)
- 청구 계약 종류는 MCA(MicrosoftCustomerAgreement)이고, 청구 테넌트 ID가 이 디렉터리의 테넌트 ID와 달랐음(조회)
- MCA 청구 계정은 기본 테넌트 하나에 묶이고 다른 테넌트의 구독도 연결할 수 있으며, 청구 역할은 기본·연결 테넌트의 ID에만 줄 수 있음(문서)
- 청구 계정 쪽 정보가 더 필요하면 청구 테넌트의 청구 계정 소유자에게 요청해야 함

> 근거 표기: 조회 = 이 샌드박스 테넌트에서 직접 읽은 값 · 문서 = Microsoft Learn · 확인 불가 = 시도했지만 확인하지 못한 값(방법·사유 병기) · 추정 = 조회·문서로 직접 확인하지 못한 해석. 그림의 청구 계정·프로필·청구서 섹션 이름과 ID, 구독 이름, 테넌트 이름은 회색 상자로 가렸습니다. 테넌트 ID 값은 글에 적지 않고 "같다/다르다"만 적었습니다.

---

## 전체 기록

### 1. 증상

- 비용 관리 + 청구 > 청구 범위가 0건("입력한 필터와 일치하는 항목이 없습니다")이었습니다(그림 1, 19:02).
- 그래서 앱(서비스 주체)에 청구 계정 읽기 같은 청구 역할을 줄 화면까지 가지 못했습니다.
- 한편 구독 Owner로 보면 구독 개요의 "플랜"은 Azure 플랜이고, 비용 조회도 됐습니다(조회).

[![비용 관리 + 청구 > 청구 범위: 목록 0건]({{ "/assets/images/2026/11/ts-billing-01-scopes-empty.png" | relative_url }})]({{ "/assets/images/2026/11/ts-billing-01-scopes-empty.png" | relative_url }}){:target="_blank"}

*그림 1. 청구 범위 목록(19:02). 머리글 아래가 비어 있습니다. 안내 문장 속 디렉터리 이름은 가렸습니다.*

### 2. 원인 및 분석

기대값은 이 디렉터리 사용자가 볼 수 있는 청구 계정이 청구 범위에 나오고, 그 범위의 액세스 제어(IAM)에서 청구 역할을 주는 것입니다(문서).

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/ts-billing-dg-01-tenants-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/ts-billing-dg-01-tenants.png" | relative_url }}" alt="구독은 이 테넌트, MCA 청구 계정은 다른 테넌트에 있는 구조" loading="lazy"></picture>

구독 > 설정 > **청구 속성**을 열면 이 구독이 붙어 있는 청구 계정, 청구 프로필, 청구서 섹션이 이름과 ID로 나옵니다(조회).

[![구독 청구 속성: 청구 계정 이름·ID, 청구 프로필, 청구서 섹션, 플랜 Microsoft Azure Plan]({{ "/assets/images/2026/11/ts-billing-02-billing-properties.png" | relative_url }})]({{ "/assets/images/2026/11/ts-billing-02-billing-properties.png" | relative_url }}){:target="_blank"}

*그림 2. 구독 > 청구 속성(23:30). 청구 계정·프로필·청구서 섹션이 모두 채워져 있습니다. 이름과 ID는 가렸습니다.*

<details markdown="1">
<summary>앱(서비스 주체)으로 읽은 billingProperty 값 (표)</summary>

앱은 같은 정보를 구독의 billingProperty API로 읽습니다. 앱에 준 Azure 역할은 루트 관리 그룹 Reader 하나였고, 이 값이 "조회됨"으로 나왔습니다(조회).

| 항목 | 읽은 값 |
|---|---|
| 청구 계약 종류 | MicrosoftCustomerAgreement |
| 청구 프로필 상태 | Active |
| 구독 청구 상태 | Active |
| SKU | Microsoft Azure Plan |
| 청구 테넌트 ID | 이 디렉터리 테넌트 ID와 **다름** |

</details>

MCA 청구 계정은 기본 테넌트 하나에 묶이고 다른 테넌트의 구독도 연결할 수 있으며, 청구 역할은 기본·연결 테넌트의 ID에만, 관리 그룹·리소스 그룹이 아닌 청구 범위에만 줄 수 있습니다(문서). 그래서 이 디렉터리의 계정·앱에는 청구 범위가 0건으로 보인 것입니다. 이 마지막 해석은 조회값과 문서를 이은 것이고, 청구 테넌트에는 로그인하지 않았습니다.

<details markdown="1">
<summary>확인 과정 자세히 보기</summary>

#### 나눠 본 순서

1. **청구 계정이 있는가**: 있습니다. 구독 청구 속성에 청구 계정·프로필·청구서 섹션이 나옵니다(그림 2).
2. **이 디렉터리에서 보이는가**: 안 보입니다. 청구 범위 0건(그림 1).
3. **어느 테넌트의 청구 계정인가**: billingProperty의 청구 테넌트 ID가 이 디렉터리 테넌트 ID와 다릅니다(조회).
4. **앱이 구독 단위로는 읽을 수 있는가**: 읽습니다. Reader만으로 billingProperty "조회됨"(조회). 같은 실행에서 청구 쪽 구독 목록은 "해당 구독 없음"이었습니다(조회).

#### 할 수 있는 것과 없는 것

| 하려던 것 | 분류 | 이유 |
|---|---|---|
| 앱에 청구 계정 역할 주기 | 불가능 | 이 디렉터리에 청구 범위가 없음. 청구 역할은 청구 계정의 기본·연결 테넌트 ID에만 줄 수 있음(문서) |
| 구독의 청구 연결 읽기 | 해야 함(가능) | 구독 Reader 수준에서 billingProperty로 읽힘(조회) |
| 구독 범위 비용 읽기 | 해야 함(가능) | Reader로 비용 조회(Query)가 읽힘(문서·조회) |
| 청구서·다른 구독 보기 | 할 수 있음(조건부) | 청구 테넌트의 청구 계정 소유자가 이 테넌트를 연결하거나 역할을 줄 때만 가능(문서) |

#### 앞선 글과의 관계

10/22에 같은 화면(청구 범위 0건)을 보고 청구 계정 유형을 확인 불가로 남겼습니다([청구 범위와 청구 역할이 보이지 않음]({{ "/m365/troubleshooting/billing-scope-not-visible/" | relative_url }})). 그때는 비용 관리 + 청구 화면만 봤고, 구독 쪽 청구 속성과 billingProperty는 보지 않았습니다. 이번에 구독 쪽에서 읽어 계약 종류(MCA)와 청구 테넌트가 다르다는 것을 확인했습니다.

</details>

### 3. 결론

`앱에 청구 역할 주려 함 → 청구 범위 0건 → 구독 청구 속성·billingProperty 확인 → MCA, 청구 테넌트가 다름 → 이 디렉터리에서는 청구 역할 부여 불가`

청구 범위 0건은 "청구 계정이 없다"는 뜻이 아니었습니다. 구독 단위의 청구 연결 정보는 Reader만으로 충분히 읽힙니다.

### 4. 권고방안

1. 청구 범위가 0건이면 먼저 구독 > 설정 > 청구 속성을 엽니다. 청구 계정이 보이면 "없음"이 아니라 "다른 곳에 있음"입니다.
2. 자동화 앱에는 청구 역할 대신 Reader로 billingProperty를 읽게 하고, 청구 테넌트 ID가 자기 테넌트와 같은지 비교하는 항목을 둡니다.
3. 청구 계정 쪽 정보(청구서, 같은 청구 계정의 다른 구독)가 필요하면 청구 테넌트의 청구 계정 소유자에게 요청합니다. 이 테넌트에서 역할을 만들어 우회하지 않습니다.
4. 결과표에는 0건을 "청구 없음"으로 적지 않고 "청구 계정은 다른 테넌트, 이 디렉터리 범위 0건"으로 적습니다.

관련 글: [앱 등록과 상황별 최소 권한 검증]({{ "/azure/app-registration-least-privilege/" | relative_url }}) · [청구 범위와 청구 역할이 보이지 않음]({{ "/m365/troubleshooting/billing-scope-not-visible/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (5건)</summary>

- **문서**: MCA 청구 계정은 기본 테넌트 하나에 연결, 다른 테넌트 구독 연결 가능, 청구 역할은 기본·연결 테넌트 ID에만
    - 출처: [Manage tenants in your Microsoft Customer Agreement billing account](https://learn.microsoft.com/azure/cost-management-billing/microsoft-customer-agreement/manage-tenants), [Billing and tenant relationship](https://learn.microsoft.com/azure/cost-management-billing/understand/understand-billing-tenant-relationship)
- **문서**: MCA 청구 역할은 관리 그룹·리소스 그룹 범위에 줄 수 없음
    - 출처: [Plan for the Microsoft customer agreement service](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/design-area/azure-billing-microsoft-customer-agreement)
- **문서**: Reader도 Cost Management 비용 조회(Query)를 읽기 전용으로 사용
    - 출처: [Understand and work with scopes](https://learn.microsoft.com/azure/cost-management-billing/costs/understand-work-scopes)
- **조회**: 청구 범위 0건, 구독 청구 속성의 청구 계정·프로필·청구서 섹션
    - 출처: 그림 1, 2
- **조회**: billingProperty(계약 종류 MCA, 청구 테넌트 ID 불일치, 조회됨), 청구 쪽 구독 목록 "해당 구독 없음"
    - 출처: 앱(서비스 주체)의 billingProperty 조회 결과(23:33)

</details>
