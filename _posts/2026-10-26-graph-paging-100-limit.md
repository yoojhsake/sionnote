---
title: "[트러블슈팅] $top=999를 줬는데 Graph가 100건만 돌려줌 — @odata.nextLink 페이징"
date: 2026-10-26 14:40:00 +0900
categories: [m365, troubleshooting]
area: Graph·Cloud Shell·스크립트
seq: 4
tags: [트러블슈팅, Graph, 페이징, nextLink, 메시지 센터, PowerShell]
excerpt: "메시지 센터 게시물 목록이 한 번에 100건만 올 때 nextLink를 끝까지 따라가 전체(5페이지)를 읽은 기록"
toc: true
---

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell·Graph에서 직접 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못함(시도 방법·사유·다음 방법 병기). 계정·테넌트 식별자는 게시하지 않았고 캡처에서는 가렸다.

## 요약

| 항목 | 내용 |
|---|---|
| 증상 | 메시지 센터 게시물 목록을 `$top=999`로 요청했는데 **한 번에 100건**만 돌아옴 |
| 먼저 볼 것 | 응답 맨 위의 `@odata.nextLink` |
| 원인 | 서버가 한 번에 돌려주는 페이지 크기 제한. nextLink가 있으면 다음 페이지가 남아 있다는 뜻 |
| 대처 | nextLink가 없어질 때까지 따라가며 합산 |
| 결과 | **조회**: 100건씩 5페이지로 전체를 읽음 |

---

## 전체 기록

### 1. 증상

- Graph로 메시지 센터 게시물 목록을 읽을 때 `$top=999`를 줬지만 **한 번에 100건**만 돌아왔습니다(조회).
- 화면에도 "이 응답에는 @odata.nextLink 속성이 있다"는 안내가 떴습니다.

![응답에 @odata.nextLink가 포함된 Graph 응답]({{ "/assets/images/2026/10/m23-4-graph-paging-nextlink.png" | relative_url }})
*그림 1. `$top=999`로 요청했지만 응답에 `@odata.nextLink`(`$skip=100`)가 있어 다음 페이지가 남아 있음을 알려 준다. 테넌트 표시와 계정 아이콘은 가렸다.*

### 2. 먼저 확인할 것

응답 맨 위에 `@odata.nextLink`가 있는지 봅니다. 값이 있으면 **아직 다음 페이지가 남아 있다**는 뜻입니다. 오류가 아니라 정상 응답이므로, 권한이나 필터를 의심하기 전에 이것부터 확인합니다.

### 3. 시도와 결과

`nextLink`가 없어질 때까지 따라가며 합쳤습니다. 이번에는 100건씩 5페이지로 전체를 읽었습니다(조회).

```powershell
# 메시지 센터 게시물 전체 읽기(읽기 전용). 필요 범위: ServiceMessage.Read.All, 역할: Message Center Reader 이상
$uri = 'https://graph.microsoft.com/v1.0/admin/serviceAnnouncement/messages?$top=100'
$all = @()
while ($uri) {
    $r   = Invoke-MgGraphRequest -Method GET -Uri $uri
    $all += $r.value
    $uri = $r.'@odata.nextLink'     # 마지막 페이지에서는 값이 없어 반복이 끝난다
}
$all.Count
```

### 4. 대처와 원복

- 읽기 전용 조회이므로 되돌릴 변경은 없습니다.
- 첫 페이지만 보고 "전체 건수"로 적으면 **전체의 일부를 전체로 기록**하게 됩니다. 건수를 적을 때는 페이지를 끝까지 따라간 합계인지 함께 밝힙니다.

### 5. 운영에서는 이렇게 판단한다

1. 목록을 읽을 때는 **개수 제한과 `@odata.nextLink`를 항상 함께** 확인합니다.
2. 요청한 `$top`보다 적게 돌아오면 페이지 크기 제한을 먼저 의심합니다.
3. 합계는 반복이 끝난 뒤에 한 번만 셉니다.

### 6. 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 문서 | Graph 페이징(`@odata.nextLink`) | [Paging Microsoft Graph data](https://learn.microsoft.com/graph/paging) |
| 문서 | 메시지 센터 게시물 조회 | [List serviceAnnouncement messages](https://learn.microsoft.com/graph/api/serviceannouncement-list-messages?view=graph-rest-1.0) |
| 조회 | `$top=999` 요청에 100건 응답, nextLink 따라가 5페이지로 전체 | 10/24~10/26, Graph 탐색기·PowerShell |

관련 글: [조회 스크립트 결과가 전부 실패로 나올 때]({{ "/m365/troubleshooting/script-all-fail-token-expired/" | relative_url }}), [명령이 모듈 없음·환경에 따라 접속 안 될 때]({{ "/m365/troubleshooting/powershell-module-not-found/" | relative_url }})
