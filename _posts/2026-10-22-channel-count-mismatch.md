---
title: "[Troubleshooting] 관리 센터 숫자·사이트 목록과 Graph 채널 수가 다를 때"
date: 2026-10-22 10:40:00 +0900
categories: [m365, troubleshooting]
area: Teams·채널·파일
seq: 5
tags: [Teams, SharePoint, Graph, 채널, 활성 사이트, 관리 센터]
excerpt: "Graph는 채널 4개, 관리 센터는 유형별 열로 나눠 셉니다. 열을 더하면 2+1+1=4로 일치하고 채널 사이트는 링크로 묶여 있습니다"
---

Graph는 채널이 4개라는데 관리 센터 팀 목록은 열마다 숫자가 따로 있고, 활성 사이트 목록에는 채널 사이트 행조차 없습니다. 관리 센터가 채널을 표준, 비공개, 공유 열로 나눠 세기 때문이었고, 열을 더하자(2+1+1=4) 두 숫자가 일치했습니다.

## 요약

- 숫자가 틀린 것이 아니라 화면마다 세는 기준이 달랐음
- General을 표준 열에 넣고 공유 열까지 더하면 Graph 수와 맞음
- 채널 사이트는 팀 사이트 행에 묶여 보이니 정책 대상은 따로 세야 함

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다. 주소의 테넌트 부분은 `<테넌트>`로 적었습니다.

---

## 전체 기록

### 1. 증상

- Graph `allChannels`: 4개(General, ch-standard, ch-private, ch-shared)

![Teams 관리 센터 Manage teams 화면. 8 teams, Practice-Team 행이 표준 채널 2, 비공개 채널 1, 공유 채널 1]({{ "/assets/images/2026/10/d3-manage-teams.png" | relative_url }})
*그림 1. Teams 관리 센터 팀 목록(빨간 상자: Practice-Team-01, 일부 팀 이름은 가림). 표준 채널 2, 비공개 채널 1, 공유 채널 1이 각각 다른 열에 표시됩니다.*

- SharePoint 활성 사이트: **Practice-Team-01 한 행만** 보임

![SharePoint 관리 센터 활성 사이트 목록. Practice-Team-01 한 행, 채널 사이트 2개로 표시]({{ "/assets/images/2026/10/d3-active-sites.png" | relative_url }})
*그림 2. 활성 사이트 목록 (빨간 상자: Practice-Team-01 행). "채널 사이트" 열에 "사이트 2개"가 링크로 표시됩니다. 일부 사이트 이름과 주소는 가렸습니다.*

### 2. 원인 및 분석

(가) 비공개·공유 채널은 팀 사이트와 별도 사이트입니다(문서). (나) 조회 값:

| 비교 | 값 | 결과 |
|---|---|---|
| Graph `allChannels` | General 포함 4 | - |
| 관리 센터 열 값 | 표준 2 + 비공개 1 + 공유 1 = 4 | Graph와 일치 |
| 활성 사이트 | 팀 사이트 1행 + 채널 사이트 2개 | 비공개·공유 채널 사이트 각 1개와 일치 |

<details markdown="1">
<summary>확인 과정 자세히 보기</summary>

#### 확인한 순서

1. Graph 채널 목록과 열 값을 같은 기준으로 셉니다. Graph 목록에는 General이 들어 있으니, 관리 센터에서 General이 표준 채널 열에 들어가는지 봅니다.
2. 열 이름을 끝까지 읽습니다. 표준 채널과 비공개 채널 열만 보고 공유 채널 열을 놓치지 않았는지 봅니다.
3. 채널 사이트를 직접 열어 봅니다. 공유, 비공개 채널의 폴더 주소를 브라우저에서 열어 문서 라이브러리가 있는지 봅니다.

#### 시도와 결과

처음에는 관리 센터의 표준, 비공개 두 열만 읽고 "공유 채널이 이 두 열에 잡히지 않는다"고 판단해 집계 위치를 확인 불가로 남겼습니다. 다시 보니 화면에는 공유 채널 열이 따로 있었고(그림 1) 값이 1이었습니다. 공유 채널은 그 열에 집계되는 것으로 정정합니다(조회).

공유 채널 사이트(`…/sites/Practice-Team-01-ch-shared`)는 직접 열어 문서 라이브러리가 있는 것을 확인했습니다(조회). 링크 안으로 들어가 설정을 바꾸지는 않았습니다.

</details>

### 3. 결론

`유형별 열 / General 포함 목록 / 링크로 묶인 채널 사이트 → 세는 기준 차이`

처음 확인 불가로 남겼던 공유 채널 집계 위치는 공유 채널 열로 정정했습니다.

### 4. 권고방안

1. 조치: 숫자에는 화면과 열 기준을 함께 적고, 채널 사이트는 "채널 사이트" 링크로 들어가 점검합니다.
2. 조치 후 확인: 열 합계 = Graph 채널 수, 채널 사이트 수 = 비공개·공유 채널 수
3. 하지 말아야 할 것: 활성 사이트 한 행으로 사이트 수 세기(보존, 외부 공유, 백업 정책 대상 누락)

관련 글: [Teams 저장 구조: 채널 유형별 파일과 일정 위치]({{ "/m365/d3-teams-storage/" | relative_url }}) · [공유 채널이 unknownFutureValue로 보일 때]({{ "/m365/troubleshooting/shared-channel-unknownfuturevalue/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (4건)</summary>

- 조회: Graph 채널 4개, 관리 센터 열 값(표준 2, 비공개 1, 공유 1), 활성 사이트 1행 + 채널 사이트 2개
    - 출처: Graph, Teams 관리 센터, SharePoint 관리 센터
- 조회: 공유 채널 사이트 주소를 열면 문서 라이브러리가 있음
    - 출처: SharePoint 화면
- 문서: 채널 사이트는 활성 사이트의 "채널 사이트" 열 링크로 들어가 사이트별 공유 설정을 바꿈
    - 출처: [Change sharing settings for a site](https://learn.microsoft.com/sharepoint/change-external-sharing-site)
- 문서: 표준 채널은 팀 사이트 공유, 비공개·공유 채널은 각각 별도 사이트
    - 출처: [Teams connected sites](https://learn.microsoft.com/sharepoint/teams-connected-sites)

</details>
