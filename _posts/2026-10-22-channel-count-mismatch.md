---
title: "[Troubleshooting] 관리 센터 숫자·사이트 목록과 Graph 채널 수가 다를 때"
date: 2026-10-22 10:40:00 +0900
categories: [m365, troubleshooting]
area: Teams·채널·파일
seq: 5
tags: [Teams, SharePoint, Graph, 채널, 활성 사이트, 관리 센터]
excerpt: "Graph는 채널 4개, 관리 센터는 유형별 열로 나눠 센다. 열을 더하면 2+1+1=4로 일치하고 채널 사이트는 링크로 묶여 있다"
---

Graph는 채널이 4개라는데 관리 센터 팀 목록은 열마다 숫자가 따로 있고, 활성 사이트 목록에는 채널 사이트 행조차 없습니다. 관리 센터가 채널을 표준, 비공개, 공유 열로 나눠 세기 때문이었고, 열을 더하자(2+1+1=4) 두 숫자가 일치했습니다.

## 요약

- Graph `allChannels`는 채널 4개(General 포함)인데 관리 센터 팀 목록은 열마다 숫자가 따로 있어 바로 맞춰지지 않음
- 활성 사이트 목록에도 채널 사이트가 별도 행으로 없었음
- 관리 센터는 채널을 표준, 비공개, 공유 열로 나눠 셈. General은 표준 채널 열에 들어가고, 채널 사이트는 팀 사이트 행의 "채널 사이트" 열에 링크로 묶임
- 열 값을 더하면 2+1+1=4로 Graph와 일치. 채널 사이트는 링크로 들어가 개별 사이트를 고름(문서)
- 공유 채널 사이트 주소를 직접 열어 문서 라이브러리가 있는 것도 확인함

> 근거 표기: 조회 = 이 테넌트에서 직접 읽은 값, 문서 = Microsoft Learn, 확인 불가 = 시도했지만 확인하지 못한 값(방법과 사유 병기). 테넌트 ID, 도메인, 계정, 사용자 이름 등 비공개 정보는 가리거나 게시하지 않았습니다. 주소의 테넌트 부분은 `<테넌트>`로 적었습니다.

---

## 전체 기록

### 1. 증상

Practice-Team-01에 채널 3종을 만든 뒤 숫자를 맞춰 봤습니다. Graph `allChannels`는 4개(General, ch-standard, ch-private, ch-shared)를 돌려줬는데, Teams 관리 센터 팀 목록에서는 Practice-Team-01 행이 열마다 다른 숫자를 보였습니다.

![Teams 관리 센터 Manage teams 화면. 8 teams, Practice-Team 행이 표준 채널 2, 비공개 채널 1, 공유 채널 1]({{ "/assets/images/2026/10/d3-manage-teams.png" | relative_url }})
*그림 1. Teams 관리 센터 팀 목록(빨간 상자: Practice-Team-01, 일부 팀 이름은 가림). 표준 채널 2, 비공개 채널 1, 공유 채널 1이 각각 다른 열에 표시됩니다.*

SharePoint 관리 센터의 활성 사이트에서는 **Practice-Team-01 한 행만** 보였습니다. 채널 사이트는 별도 행이 아니라 "사이트 2개"라는 표시로 묶여 있었습니다.

![SharePoint 관리 센터 활성 사이트 목록. Practice-Team-01 한 행, 채널 사이트 2개로 표시]({{ "/assets/images/2026/10/d3-active-sites.png" | relative_url }})
*그림 2. 활성 사이트 목록 (빨간 상자: Practice-Team-01 행). "채널 사이트" 열에 "사이트 2개"가 링크로 표시됩니다.*

### 2. 원인과 해결

숫자가 틀린 게 아니었습니다. 화면마다 세는 기준이 달랐을 뿐입니다.

| 비교 | 값 | 결과 |
|---|---|---|
| Graph `allChannels` | General 1 + ch-standard 1 + ch-private 1 + ch-shared 1 = 4 | - |
| 관리 센터 열 값 | 표준 2 + 비공개 1 + 공유 1 = 4 | Graph와 일치 |
| 활성 사이트 | 팀 사이트 1행 + 채널 사이트 2개 | 비공개·공유 채널 사이트 각 1개와 일치 |

숫자를 맞출 때는 Graph 목록의 **General을 표준 채널에 포함**하고, 관리 센터의 공유 채널 열까지 더하면 됩니다. 채널 사이트를 점검하거나 공유 설정을 바꿔야 할 때는 활성 사이트의 "채널 사이트" 링크로 들어갑니다. 이번에는 조회만 했고 변경한 것은 없습니다.

### 3. 숫자를 보고할 때 지킬 것

팀 수나 채널 수를 보고할 때는 어느 화면의 어떤 열 기준인지 같이 적습니다. 관리 센터는 채널 유형별 열이고, Graph는 General을 포함한 채널 목록입니다.

비공개·공유 채널은 팀 사이트와 **별개의 사이트**입니다. 활성 사이트 목록의 한 행만 보고 사이트 수를 세면 안 되고, 보존, 외부 공유, 백업 정책도 채널 사이트까지 대상에 넣어 따로 잡아야 합니다.

### 4. 확인 과정

<details markdown="1">
<summary>확인 과정 자세히 보기</summary>

#### 확인한 순서

1. Graph 채널 목록과 열 값을 같은 기준으로 셉니다. Graph 목록에는 General이 들어 있으니, 관리 센터에서 General이 표준 채널 열에 들어가는지 봅니다.
2. 열 이름을 끝까지 읽습니다. 표준 채널과 비공개 채널 열만 보고 공유 채널 열을 놓치지 않았는지 봅니다.
3. 채널 사이트를 직접 열어 봅니다. 공유, 비공개 채널의 폴더 주소를 브라우저에서 열어 문서 라이브러리가 있는지 봅니다.

#### 시도와 결과

처음에는 관리 센터의 표준, 비공개 두 열만 읽고 "공유 채널이 이 두 열에 잡히지 않는다"고 판단해 집계 위치를 확인 불가로 남겼습니다. 다시 보니 화면에는 공유 채널 열이 따로 있었고(그림 1) 값이 1이었습니다. 공유 채널은 그 열에 집계되는 것으로 정정합니다(조회).

공유 채널 사이트(`…/sites/Practice-Team-01-ch-shared`)는 직접 열어 문서 라이브러리가 있는 것을 확인했습니다(조회). 문서에 따르면 SharePoint 관리 센터에서 채널 사이트는 "채널 사이트" 열의 링크로 들어가 개별 사이트를 고를 수 있고, 사이트별 외부 공유 설정을 바꿀 때도 그 경로를 씁니다. 이 실습에서는 링크 안으로 들어가 설정을 바꾸지 않았습니다.

</details>

### 5. 관련 글

- [Teams 저장 구조: 채널 유형별 파일과 일정 위치]({{ "/m365/d3-teams-storage/" | relative_url }})
- [공유 채널이 unknownFutureValue로 보일 때]({{ "/m365/troubleshooting/shared-channel-unknownfuturevalue/" | relative_url }})

### 6. 근거 자료

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
