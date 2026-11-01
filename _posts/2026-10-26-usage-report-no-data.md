---
title: "[Troubleshooting] 사용 현황 보고서가 '데이터 없음'이고 Graph는 404 UnknownTenantId"
date: 2026-10-27 19:40:00 +0900
categories: [m365, troubleshooting]
area: 보고서·감사·청구
seq: 1
tags: [Troubleshooting, 사용 현황 보고서, UnknownTenantId, Graph, "404", Teams 보고서]
excerpt: "사용 현황 보고서가 비고 Graph는 404 UnknownTenantId일 때, 권한(403)이 아닌 데이터 부재(404)로 보고 다른 화면에서 읽었습니다"
toc: true
---

관리 센터 사용 현황은 "데이터 없음", Graph 보고서는 HTTP 404 `UnknownTenantId`였습니다. 403이 아니라 404이니 권한 문제가 아니라 보고서 서비스에 데이터가 없는 상태로 보았고, 10/26~10/27에 3회 읽어도 비어 있어 다른 화면에서 같은 정보를 읽었습니다.

## 요약

- 403이 아닌 404라서 권한이 아니라 보고서 데이터 부재로 판단함
- 응답 코드를 먼저 보고, 비어 있으면 0건이 아닌 "데이터 없음"으로 적음
- 권한을 추가하면 결과가 달라지는지는 시도하지 않아 확인 불가

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다. 요청 ID도 게시하지 않았습니다. 조회 값은 화면, PowerShell, Graph에서 읽었습니다.

---

## 전체 기록

### 1. 증상

- 화면: Microsoft 365 관리 센터 > 보고서 > 사용 현황에 "There is no data for this report."(조회, 10/26 23:39). 화면 설명은 "모든 보고 기간에 대한 데이터가 즉시 존재하지 않으며, 보고서는 48시간 이내에 사용할 수 있다"
- Graph: `GET /reports/getTeamsTeamActivityDetail(period='D7')`가 HTTP 404, `UnknownTenantId`("이 테넌트 ID를 인식하지 못한다")(조회)

![사용 현황 보고서가 데이터 없음으로 표시된 화면]({{ "/assets/images/2026/10/m23-2-usage-report-no-data.png" | relative_url }})
*그림 1. 관리 센터 사용 현황 화면. 모든 보고서 탭에서 "There is no data for this report."가 나옵니다. 테넌트 표시는 가렸습니다.*

![Graph 보고서 호출이 UnknownTenantId 404로 응답]({{ "/assets/images/2026/10/m23-1-teams-report-unknowntenantid.png" | relative_url }})
*그림 2. `getTeamsTeamActivityDetail(period='D7')` 호출 결과. 404이며 오류 코드는 UnknownTenantId입니다. 응답 속 테넌트 ID와 요청 ID는 가렸습니다.*

### 2. 원인 및 분석

응답 코드에 따라 방향이 다릅니다([reportRoot: getTeamsTeamActivityDetail](https://learn.microsoft.com/graph/api/reportroot-getteamsteamactivitydetail?view=graph-rest-1.0)).

- 403 Forbidden / accessDenied: 토큰 범위나 역할 부족(이번은 아님)
- 404 `UnknownTenantId`: 요청은 받아들여졌지만 보고서 서비스에 이 테넌트 데이터가 없음(이번 경우)

Reports.Read.All을 동의하지 않았는데도 권한 오류가 아닌 UnknownTenantId였습니다(조회).

시험 메시지를 남긴 뒤 세 번(10/26, 10/27 10:29, 19:17) 읽어도 같은 404였습니다.

<details markdown="1">
<summary>확인 과정 자세히 보기</summary>

1. 활동 만들기: 새 테넌트는 사용 이력이 거의 없어 비어 있을 수 있으므로 표준 채널에 시험 메시지 2건을 남겼습니다(10/26 19시대).
2. 시각을 달리해 반복: 같은 Graph 호출을 10/27 10:29와 19:17(KST)에 실행했습니다.
    - 두 번 모두 같은 404 `UnknownTenantId`였습니다(조회).
    - Teams 관리 센터의 팀 사용 현황 보고서도 "데이터를 불러올 수 없음"이었습니다(조회).

</details>

### 3. 결론

`보고서 서비스에 테넌트 데이터 없음 → 화면 "데이터 없음" + Graph 404 UnknownTenantId`

일시적 오류는 아니며, 관찰 결과만 적고 비어 있는 이유는 적지 않습니다. 권한이 충분해서 나온 응답이라고는 말할 수 없고, 권한을 추가하면 결과가 달라지는지는 시도하지 않아 확인 불가입니다. 변경은 시험 메시지 2건뿐입니다(원복 불필요).

### 4. 권고방안

1. 조치: 응답 코드를 먼저 읽습니다. 404나 서비스 상태 오류면 데이터·서비스 상태 쪽이고, 화면과 Graph가 모두 비어 있으면 권한 문제일 가능성은 낮습니다.
2. 조치 후 확인: 몇 시간 뒤, 하루 뒤 같은 요청으로 "지연"인지 "고정된 상태"인지 나눕니다. 값이 꼭 필요하면 다른 경로(Teams 관리 센터 정책 화면, Entra 로그인 로그 등)로 읽습니다.
3. 하지 말아야 할 것: 0건으로 적지 않습니다("활동 없음"처럼 읽힘). "데이터 없음 응답"으로 적고, 404에 권한 동의부터 늘리지 않습니다.

관련 글: [실측 Purview·Azure 거버넌스]({{ "/m365/measure-purview-azure/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (3건)</summary>

- **문서**: Teams 팀 활동 보고서 API, [reportRoot: getTeamsTeamActivityDetail](https://learn.microsoft.com/graph/api/reportroot-getteamsteamactivitydetail?view=graph-rest-1.0)
- **조회**: 관리 센터 사용 현황 "데이터 없음" (10/26 23:39)
- **조회**: Graph 보고서 404 `UnknownTenantId` (10/26, 10/27 10:29, 10/27 19:17)

</details>
