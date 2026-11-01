---
title: "[Troubleshooting] 같은 설정인데 화면 값과 PowerShell 값이 다르게 읽힘"
date: 2026-10-26 15:20:00 +0900
categories: [m365, troubleshooting]
area: Graph·Cloud Shell·스크립트
seq: 6
tags: [Troubleshooting, SharePoint, Get-SPOTenant, DefaultLinkPermission, 화면과 명령 차이]
excerpt: "기본 링크 권한이 화면은 '편집', Get-SPOTenant는 None. 추정하지 않고 둘 다 기록하고 Graph로 나머지를 대조했습니다."
toc: true
---

SharePoint 기본 링크 권한이 화면에서는 "편집"인데 `Get-SPOTenant`의 `DefaultLinkPermission`은 None으로 나왔습니다. 어느 쪽이 맞는지 추정하지 않고 둘 다 기록했고, Graph로 읽은 나머지 속성은 화면과 일치했습니다.

## 요약

- 화면과 명령 값이 달라 어느 쪽도 단정하지 않고 두 값을 모두 기록함
- 값과 읽은 방법, 시각을 남기고 Graph 같은 다른 경로로 대조하면 됨
- None이 화면의 편집에 대응하는지는 문서에 설명이 없어 확인 불가

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다. 조회 값은 화면, PowerShell, Graph에서 읽었습니다.

---

## 전체 기록

### 1. 증상

- SharePoint 기본 링크 권한: 화면 "편집" / `Get-SPOTenant`의 `DefaultLinkPermission` None(조회, 10/26)

![SharePoint 관리 센터 공유 설정의 파일 및 폴더 링크 항목]({{ "/assets/images/2026/10/spo-sharing-default-link.png" | relative_url }})
*그림 1. SharePoint 관리 센터 > 정책 > 공유의 "파일 및 폴더 링크". 기본 사용 권한은 "편집"이 선택되어 있습니다. 같은 화면의 링크 유형은 두 항목에 선택 표시가 있는 것처럼 보여, 표시만으로는 선택 상태를 단정하기 어렵습니다.*

PowerShell 출력은 캡처가 남아 있지 않아 값만 적었습니다.

### 2. 원인 및 분석

화면과 속성 이름은 1:1이 아닐 수 있는데, [Get-SPOTenant](https://learn.microsoft.com/powershell/module/sharepoint-online/get-spotenant) 문서에는 `None`과 "편집"의 대응 설명이 없습니다. Graph(`/admin/sharepoint/settings`)로 읽은 나머지 속성은 화면과 일치했습니다(조회).

<details markdown="1">
<summary>확인 과정 자세히 보기 (그림 1장)</summary>

1. 두 값을 모두 기록하고, 어느 쪽이 맞는지 추정으로 정하지 않고 "해석 차이"로 적었습니다.
2. `Get-SPOTenant` 문서에서 대응 관계를 찾았지만 설명이 없었습니다.
3. 같은 설정을 나타내는 다른 속성(익명 링크의 파일, 폴더 권한 값)을 판단에 썼습니다.
4. 같은 설정을 Graph로 읽어 나머지 속성이 화면과 일치하는 것을 확인했습니다(조회).

![Graph Explorer에서 admin/sharepoint/settings를 조회한 응답]({{ "/assets/images/2026/10/graph-sharepoint-settings.png" | relative_url }})
*그림 2. Graph Explorer의 `GET /v1.0/admin/sharepoint/settings` 응답(200 OK). 테넌트 표시는 가렸습니다. 이 응답의 속성을 화면 값과 비교했습니다.*

화면의 라디오 버튼이나 슬라이더 표시만으로 선택 값이 불분명하면, 브라우저에서 해당 요소의 선택 상태를 직접 읽어 확인했습니다. 눈으로 읽은 값에 근거가 약하면 그렇다고 적습니다.

화면과 Graph의 건수가 며칠 사이 조금 다를 때는, 시간이 지난 만큼 항목이 바뀐 것으로 **추정**하고 추정이라고 표시했습니다. 확인한 것은 아닙니다(다음 방법: 같은 시각에 화면과 Graph를 함께 읽어 대조).

</details>

### 3. 결론

`대응 설명 없음 → "편집" / None → 단정 불가`

원인은 확인 불가입니다(시도: 문서 확인 / 막힌 이유: 설명 없음 / 다음 방법: 같은 설정의 다른 속성으로 판단). 두 값을 "해석 차이"로 기록했습니다(읽기 전용).

### 4. 권고방안

1. 조치: 불일치는 정보로 보고, 결과 표에 화면 값과 명령 값, 각각 읽은 방법·시각, 판단 근거 속성을 적습니다.
2. 조치 후 확인: 다른 속성(익명 링크 권한 값)이나 Graph 값이 판단을 뒷받침하면 됩니다.
3. 하지 말아야 할 것: 한쪽으로 단정하거나 한 값을 지우지 않습니다.

관련 글: [실측 SharePoint·OneDrive·M365 관리 센터]({{ "/m365/measure-sharepoint-admin/" | relative_url }}) · [빈 값(null)에서 계산 오류·누락]({{ "/m365/troubleshooting/null-values-in-scripts/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (4건)</summary>

- 문서: SharePoint 테넌트 설정, [Get-SPOTenant](https://learn.microsoft.com/powershell/module/sharepoint-online/get-spotenant)
- 조회: 기본 링크 권한은 화면 "편집", `DefaultLinkPermission` = None (10/26)
- 조회: Graph `/admin/sharepoint/settings`의 나머지 속성이 화면과 일치 (10/26)
- 확인 불가: `None`이 화면의 "편집"에 대응하는지
    - 시도: 문서 확인. 막힌 이유: 설명 없음.
    - 다음 방법: 다른 속성(익명 링크 권한 값)과 Graph 값으로 판단

</details>
