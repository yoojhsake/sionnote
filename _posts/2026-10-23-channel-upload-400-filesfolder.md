---
title: "[Troubleshooting] 채널 경로로 업로드하면 400 \"AAD 계정에서는 지원되지 않음\""
date: 2026-10-23 10:25:00 +0900
categories: [m365, troubleshooting]
area: Teams·채널·파일
seq: 2
tags: [Teams, Graph, filesFolder, "400", 업로드, Cloud Shell]
excerpt: "채널 경로로 올리면 세 채널 모두 400. driveId·itemId를 구해 드라이브 경로로 바꾸자 표준 채널과 General 업로드가 성공했습니다"
---

채널 경로(`filesFolder/content`)로 파일을 바로 올렸더니 세 채널 모두 "HTTP 400 - This API is not supported for AAD accounts"가 났습니다. `filesFolder`에서 `driveId`·`itemId`를 구해 드라이브 경로로 올리자 표준 채널과 General은 성공했습니다.

## 요약

- 세 채널이 모두 같은 400이라 채널 유형이 아니라 경로 문제임
- 400이면 경로부터 보고 업로드는 항상 드라이브 경로로 올리면 됨
- 채널 경로가 이 계정에서 지원되지 않는 정확한 이유는 확인 불가

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다. 토큰도 게시하지 않았습니다.

---

## 전체 기록

### 1. 증상

- 채널 주소 아래 `filesFolder/content`로 바로 `PUT` 하니 세 채널 모두 같은 400이었습니다.

![채널 경로로 바로 올렸을 때의 400 오류]({{ "/assets/images/2026/10/m14-1-badrequest.png" | relative_url }})
*그림 1. 채널 경로(`filesFolder/content`)로 바로 올렸을 때의 오류(위쪽은 실행한 명령). ch-standard, ch-private, ch-shared 모두 "HTTP 400 - This API is not supported for AAD accounts"가 출력됩니다. 프롬프트의 계정 부분은 가렸습니다.*

### 2. 원인 및 분석

문서의 업로드 경로는 `PUT drives/{driveId}/items/{itemId}:/파일명:/content`이고, 권한은 Files.ReadWrite, Files.ReadWrite.All, Sites.ReadWrite.All 중 하나입니다(문서: driveItem 업로드). 400은 권한(403)이 아니라 요청 형식 문제라 경로부터 봤습니다.

- 드라이브 경로 결과: 표준·General 성공 / 비공개·공유 **403 accessDenied**(형식은 통과, 원인은 토큰 범위: [채널 403 글]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }}))

<details markdown="1">
<summary>확인 과정 자세히 보기 (그림 1장)</summary>

#### 처음 의심한 것

1. 유형이 다른 세 채널에서 같은 400인가: 세 채널 모두 같은 400이었고, 채널 유형이나 멤버십이 아니라 경로 문제로 봤습니다.
2. 채널의 파일 폴더 정보(`filesFolder`)는 읽히는가: 읽혔습니다.
    - 폴더가 들어 있는 드라이브의 `driveId`와 폴더 항목의 `itemId`를 얻을 수 있음
3. 업로드 문서가 안내하는 경로는 무엇인가: 드라이브와 항목을 지정하는 `PUT drives/{driveId}/items/{itemId}:/파일명:/content` (문서: driveItem 업로드)

처음 실패한 스크립트는 다음과 같습니다(준비 코드: [채널 403 글]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }})의 "공통 준비 코드").

```powershell
foreach ($c in $ch | Where-Object displayName -ne 'General') {
  $u = "$B/teams/$tid/channels/$($c.id)/filesFolder/content"
  try { Invoke-RestMethod -Method Put -Headers $h -Uri $u -ContentType 'text/plain' -Body 'x' | Out-Null; "OK $($c.displayName)" }
  catch { "$($c.displayName): HTTP $($_.Exception.Response.StatusCode.value__) - $(($_.ErrorDetails.Message | ConvertFrom-Json).error.message)" }
}
```

#### 시도와 결과

채널마다 `filesFolder`를 조회해 driveId와 itemId를 구한 뒤 드라이브 경로로 올렸습니다.

```powershell
foreach ($c in $ch) {
  $ff = Invoke-RestMethod -Headers $h -Uri "$B/teams/$tid/channels/$($c.id)/filesFolder"
  $u  = "$B/drives/$($ff.parentReference.driveId)/items/$($ff.id):/zz-test.txt:/content"
  try { Invoke-RestMethod -Method Put -Headers $h -Uri $u -ContentType 'text/plain' -Body 'zz-test' | Out-Null; "UPLOAD OK zz-test.txt -> $($c.displayName)" }
  catch { "UPLOAD $($c.displayName): $($_.Exception.Response.StatusCode.value__) ($($_.Exception.Response.ReasonPhrase)) $(($_.ErrorDetails.Message | ConvertFrom-Json).error.code)" }
}
```

*이 스크립트는 채널마다 파일 폴더의 driveId와 itemId를 읽은 뒤 `PUT .../content`로 시험 파일을 올리고, 실패하면 HTTP 코드와 오류 코드만 출력합니다. 같은 파일명으로 다시 올리면 표준 채널과 General의 기존 zz-test.txt가 덮어써집니다.*

![채널별 업로드 결과]({{ "/assets/images/2026/10/m13-1-upload-result.png" | relative_url }})
*그림 2. 드라이브 경로로 올린 결과(위쪽은 실행한 명령, 아래는 출력). ch-standard와 General은 "UPLOAD OK zz-test.txt", 비공개(ch-private)와 공유(ch-shared)는 "403 (Forbidden) accessDenied"가 출력됩니다. 프롬프트의 계정 부분은 가렸습니다.*

채널 경로(`filesFolder/content`)가 이 계정에서 지원되지 않는 정확한 이유는 확인 불가로 남깁니다.

- 시도: 세 채널 모두 같은 경로로 업로드, 모두 같은 400
- 사유: 응답 문구 외에 이유를 알려 주는 내용이 없음
- 다음 방법: 문서가 안내하는 드라이브 경로(driveId, itemId)를 기준 방식으로 삼고 채널 경로는 쓰지 않음

</details>

### 3. 결론

채널 경로(`filesFolder/content`)로 `PUT` → 세 채널 모두 400 → 드라이브 경로로 바꾸자 표준 채널과 General 성공

채널 경로가 이 계정에서 지원되지 않는 정확한 이유는 확인 불가입니다(응답 문구 외에 이유가 없음, 시도와 다음 방법은 확인 과정).

### 4. 권고방안

1. 조치: 채널마다 `filesFolder`로 driveId·itemId를 구해 드라이브 경로로 올립니다.
2. 확인: 400이 사라지고 파일이 저장 위치에 있으면 됩니다. 400은 형식·경로, 403은 권한·범위부터 봅니다.
3. 정리: 경로를 잘못 지정해 생긴 `zz-x.txt`(생긴 정확한 위치는 이 글에서 확정하지 않음)는 정리 목록에 넣었고, 표준 채널과 General의 `zz-test*.txt`는 팀 삭제 때 지웁니다(같은 이름으로 올리면 덮어씀).

관련 글: [비공개·공유 채널 파일 403: 멤버십인가 토큰 범위인가]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }}) · [Cloud Shell 토큰으로 되는 Graph 호출과 안 되는 호출]({{ "/m365/troubleshooting/cloud-shell-graph-token-scope/" | relative_url }}) · [응답은 403인데 파일이 생김]({{ "/m365/troubleshooting/upload-403-but-file-created/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (4건)</summary>

- 조회: 채널 경로 업로드는 세 채널 모두 HTTP 400 "This API is not supported for AAD accounts"(그림 1)
    - 출처: Cloud Shell(Graph)
- 조회: 드라이브 경로 업로드는 표준과 General 성공, 비공개·공유 403(그림 2)
    - 출처: Cloud Shell(Graph)
- 문서: 업로드 경로와 필요한 Graph 권한
    - 출처: [Upload or replace the contents of a driveItem](https://learn.microsoft.com/graph/api/driveitem-put-content?view=graph-rest-1.0)
- 문서: 채널 파일 폴더 정보 조회
    - 출처: [Get filesFolder](https://learn.microsoft.com/graph/api/channel-get-filesfolder?view=graph-rest-1.0)

</details>
