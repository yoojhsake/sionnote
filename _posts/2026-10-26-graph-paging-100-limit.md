---
title: "[Troubleshooting] $top=999를 줬는데 Graph가 100건만 돌려줌: @odata.nextLink 페이징"
date: 2026-10-26 14:40:00 +0900
categories: [m365, troubleshooting]
area: Graph·Cloud Shell·스크립트
seq: 4
tags: [Troubleshooting, Graph, 페이징, nextLink, 메시지 센터, PowerShell]
excerpt: "$top=999를 줘도 100건만 왔습니다. @odata.nextLink를 끝까지 따라가 100건씩 5페이지로 전체를 읽었습니다."
toc: true
---

`$top=999`로 메시지 센터 게시물을 요청했는데 100건만 돌아왔습니다. 응답 맨 위의 `@odata.nextLink`를 없어질 때까지 따라가니 100건씩 5페이지로 전체를 읽을 수 있었습니다.

## 요약

- 요청 건수를 크게 줘도 이 API의 기본 페이지 크기(100)로 100건씩만 옴(`Prefer: odata.maxpagesize`로 최대 1000까지 지정 가능, 문서). `$top=999`가 무시된 이유는 이 글에서 확인하지 않음
- 응답에 nextLink가 있으면 없어질 때까지 따라가며 합산하면 됨
- 첫 페이지 건수를 전체 건수로 기록하지 않도록 주의해야 함

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다. 조회 값은 화면, PowerShell, Graph에서 읽었습니다.

---

## 전체 기록

### 1. 증상

- 메시지 센터 게시물을 `$top=999`로 요청했는데 100건만 오고 nextLink 안내가 뜸(조회)

![응답에 @odata.nextLink가 포함된 Graph 응답]({{ "/assets/images/2026/10/m23-4-graph-paging-nextlink.png" | relative_url }})
*그림 1. `$top=999`로 요청했지만 응답에 `@odata.nextLink`(`$skip=100`)가 있어 다음 페이지가 남아 있음을 알려 줍니다. 테넌트 표시와 계정 아이콘은 가렸습니다.*

### 2. 원인 및 분석

서버 페이지 크기 제한으로 `$top`보다 적게 오며, nextLink는 다음 페이지가 있다는 뜻입니다([Paging Microsoft Graph data](https://learn.microsoft.com/graph/paging)). 정상 응답이며, 따라가니 100건씩 5페이지였습니다(조회). 이 API의 기본 페이지 크기는 100이고 `Prefer: odata.maxpagesize` 헤더로 최대 1000까지 지정할 수 있다고 문서가 설명합니다([List serviceAnnouncement messages](https://learn.microsoft.com/graph/api/serviceannouncement-list-messages?view=graph-rest-1.0)). `$top=999`가 무시된 이유는 이 글에서 확인하지 않았고, 전체 건수(`$all.Count`)는 기록하지 않았습니다.

### 3. 결론

`페이지 크기 제한 → 100건 + nextLink → 첫 페이지만 보면 일부를 전체로 앎`

끝까지 따라가 전체를 읽었습니다(읽기 전용).

### 4. 권고방안

1. 조치: `nextLink`가 없어질 때까지 따라가며 합칩니다.

    ```powershell
    # 메시지 센터 게시물 전체 읽기(읽기 전용). 필요 범위: ServiceMessage.Read.All (역할 요구는 문서 확인 필요)
    $uri = 'https://graph.microsoft.com/v1.0/admin/serviceAnnouncement/messages?$top=100'
    $all = @()
    while ($uri) {
        $r   = Invoke-MgGraphRequest -Method GET -Uri $uri
        $all += $r.value
        $uri = $r.'@odata.nextLink'     # 마지막 페이지에서는 값이 없어 반복이 끝난다
    }
    $all.Count
    ```

2. 조치 후 확인: 반복이 끝난 뒤 `$all.Count`를 세고 페이지 합계임을 밝혀 적습니다.
3. 하지 말아야 할 것: 권한·필터부터 의심하거나 첫 페이지 건수를 전체로 적지 않습니다.

관련 글: [조회 스크립트 결과가 전부 실패로 나올 때]({{ "/m365/troubleshooting/script-all-fail-token-expired/" | relative_url }}) · [명령이 모듈 없음, 환경에 따라 접속 안 될 때]({{ "/m365/troubleshooting/powershell-module-not-found/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (3건)</summary>

- **문서**: Graph 페이징(`@odata.nextLink`)
    - 출처: [Paging Microsoft Graph data](https://learn.microsoft.com/graph/paging)
- **문서**: 메시지 센터 게시물 조회
    - 출처: [List serviceAnnouncement messages](https://learn.microsoft.com/graph/api/serviceannouncement-list-messages?view=graph-rest-1.0)
- **조회**: `$top=999` 요청에 100건 응답, nextLink 따라가 5페이지로 전체
    - 출처: 10/24~10/26, Graph 탐색기와 PowerShell

</details>
