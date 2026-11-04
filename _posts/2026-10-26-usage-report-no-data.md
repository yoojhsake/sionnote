---
title: "[Troubleshooting] 사용 현황 보고서가 '데이터 없음'이고 Graph는 404 UnknownTenantId"
date: 2026-10-27 19:40:00 +0900
categories: [m365, troubleshooting]
area: 보고서·감사·청구
seq: 1
tags: [Troubleshooting, 사용 현황 보고서, UnknownTenantId, Graph, "404", Teams 보고서]
excerpt: "사용 현황 보고서가 비고 Graph는 404 UnknownTenantId일 때, 403이 아니라 404였던 점과 화면·Graph 모두 비어 있던 관찰을 적고 다른 화면에서 읽었습니다"
toc: true
---

관리 센터 사용 현황은 "데이터 없음", Graph 보고서는 HTTP 404 `UnknownTenantId`였습니다. 403이 아니라 404였고 관리 센터 화면도 비어 있어, 권한 부족보다 보고서 쪽 상태일 가능성을 먼저 보았습니다(추정). 10/26~10/27에 3회 읽어도 비어 있어 다른 화면에서 같은 정보를 읽었습니다.

## 요약

- 403이 아닌 404이고 관리 센터 화면도 비어 있어, 권한 부족보다 보고서 쪽 상태일 가능성을 먼저 봄(권한 추가 시험은 하지 않음)
- 응답 코드를 먼저 보고, 비어 있으면 0건이 아닌 "데이터 없음"으로 적음
- 그 시점의 응답만 적었고, 지연인지 고정된 상태인지는 가리지 못함

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다. 요청 ID도 게시하지 않았습니다. 조회 값은 화면, PowerShell, Graph에서 읽었습니다.

---

## 전체 기록

### 1. 증상

- 화면: Microsoft 365 관리 센터 > 보고서 > 사용 현황 개요 화면에 "There is no data for this report."(조회, 10/26 23:39). 화면 설명은 "모든 보고 기간에 대한 데이터가 즉시 존재하지 않으며, 보고서는 48시간 이내에 사용할 수 있다"
- Graph: `GET /reports/getTeamsTeamActivityDetail(period='D7')`가 HTTP 404, 최상위 code는 `UnknownError`이고 message 안에 `UnknownTenantId`("이 테넌트 ID를 인식하지 못한다")가 들어 있습니다(조회)

![사용 현황 보고서가 데이터 없음으로 표시된 화면]({{ "/assets/images/2026/10/m23-2-usage-report-no-data.png" | relative_url }})
*그림 1. 관리 센터 사용 현황 개요 화면. 이 화면에서 "There is no data for this report."가 표시됩니다(다른 보고서 탭은 열어 보지 않음). 테넌트 표시는 가렸습니다.*

![Graph 보고서 호출이 UnknownTenantId 404로 응답]({{ "/assets/images/2026/10/m23-1-teams-report-unknowntenantid.png" | relative_url }})
*그림 2. `getTeamsTeamActivityDetail(period='D7')` 호출 결과. 404(Not Found)이며 최상위 오류 코드는 UnknownError, 메시지 안에 UnknownTenantId가 들어 있습니다. 응답 속 테넌트 ID와 요청 ID는 가렸습니다.*

### 2. 원인 및 분석

이 API의 문서([reportRoot: getTeamsTeamActivityDetail](https://learn.microsoft.com/graph/api/reportroot-getteamsteamactivitydetail?view=graph-rest-1.0))에는 성공 시 302 응답만 있고 403/404의 의미는 없습니다. 아래 구분은 문서가 아니라 이번 관찰에 근거한 추정입니다.

- 403 accessDenied: 일반적으로 토큰 범위나 역할 부족 때 나오는 응답(이번엔 나오지 않음)
- 404 `UnknownTenantId`: "이 테넌트 ID를 인식하지 못한다"는 응답. 원인은 이 글에서 추적하지 않았습니다

Reports.Read.All을 동의하지 않았는데도 권한 오류가 아닌 UnknownTenantId였습니다(조회). 이것만으로 권한이 충분하다고는 말할 수 없습니다.

시험 메시지를 남긴 뒤 세 번(10/26, 10/27 10:29, 19:17) 읽어도 같은 404였습니다.

<details markdown="1">
<summary>확인 과정 자세히 보기</summary>

1. 활동 만들기: 새 테넌트는 사용 이력이 거의 없어 비어 있을 수 있으므로 표준 채널에 시험 메시지 2건을 남겼습니다(10/26 19시대).
2. 시각을 달리해 반복: 같은 Graph 호출을 10/27 10:29와 19:17(KST)에 실행했습니다.
    - 두 번 모두 같은 404 `UnknownTenantId`였습니다(조회).
    - Teams 관리 센터의 팀 사용 현황 보고서도 "데이터를 불러올 수 없음"이었습니다(조회).

</details>

### 3. 결론

`화면 "데이터 없음" + Graph 404 UnknownTenantId (화면·Graph 모두 비어 있음, 관찰)`

관찰은 10/26~10/27 약 24시간 동안 3회뿐이고 화면 안내의 48시간 이내 범위 안이라, 지연인지 고정된 상태인지는 가리지 못했습니다. 관찰 결과만 적고 비어 있는 이유는 적지 않습니다. 권한이 충분해서 나온 응답이라고는 말할 수 없고, 권한을 추가해 보는 시험은 하지 않았습니다. 변경은 시험 메시지 2건뿐입니다(원복 불필요).

### 4. 권고방안

1. 조치: 응답 코드를 먼저 읽습니다. 404나 서비스 상태 오류면 데이터·서비스 상태 쪽이고, 화면과 Graph가 모두 비어 있으면 권한 문제인지는 가리지 못했습니다(권한을 추가해 보는 시험은 하지 않음).
2. 조치 후 확인: 몇 시간 뒤, 하루 뒤 같은 요청으로 "지연"인지 "고정된 상태"인지 나눕니다. 값이 꼭 필요하면 다른 경로(Teams 관리 센터 정책 화면, Entra 로그인 로그 등)로 읽습니다.
3. 하지 말아야 할 것: 0건으로 적지 않습니다("활동 없음"처럼 읽힘). "데이터 없음 응답"으로 적고, 404일 때는 응답 코드와 화면 상태를 먼저 비교합니다.

관련 글: [실측 Purview·Azure 거버넌스]({{ "/m365/measure-purview-azure/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (3건)</summary>

- **문서**: Teams 팀 활동 보고서 API, [reportRoot: getTeamsTeamActivityDetail](https://learn.microsoft.com/graph/api/reportroot-getteamsteamactivitydetail?view=graph-rest-1.0)
- **조회**: 관리 센터 사용 현황 "데이터 없음" (10/26 23:39)
- **조회**: Graph 보고서 404 `UnknownTenantId` (10/26, 10/27 10:29, 10/27 19:17)

</details>
