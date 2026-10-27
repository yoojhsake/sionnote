---
title: "[트러블슈팅] 채널 경로로 업로드하면 400 \"AAD 계정에서는 지원되지 않음\""
date: 2026-10-23 10:25:00 +0900
categories: [m365, troubleshooting]
area: Teams·채널·파일
seq: 2
tags: [Teams, Graph, filesFolder, "400", 업로드, Cloud Shell]
excerpt: "채널 filesFolder 경로에 바로 PUT 하면 400이 나서, filesFolder의 driveId·itemId를 구해 드라이브 경로로 올린 방법"
---

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell에서 직접 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못함(시도 방법·사유 병기). 토큰·ID·계정은 게시하지 않았습니다.

## 요약

| 항목 | 내용 |
|---|---|
| 증상 | 채널 경로(`filesFolder/content`)로 바로 올리면 세 채널 모두 "HTTP 400 - This API is not supported for AAD accounts" |
| 원인 | 이 계정(회사·학교 계정)에서는 그 경로가 지원되지 않는다는 응답. 정확한 내부 이유는 확인 불가 |
| 대처 | 채널의 `filesFolder`를 조회해 `driveId`와 `itemId`를 구한 뒤 `PUT drives/{driveId}/items/{itemId}:/파일명:/content`로 업로드 |
| 결과 | 표준 채널과 General은 업로드 성공. 비공개·공유 채널은 이 방식으로도 403(원인은 [별도 글]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }})) |

---

## 전체 기록

### 1. 증상

채널에 시험 파일을 올리려고, 채널 주소 아래 `filesFolder/content`로 바로 `PUT` 했습니다. 표준·비공개·공유 세 채널 모두 같은 400이 났습니다. 오류 문구는 "This API is not supported for AAD accounts"입니다.

![채널 경로로 바로 올렸을 때의 400 오류]({{ "/assets/images/2026/10/m14-1-badrequest.png" | relative_url }})
*그림 1. 채널 경로(`filesFolder/content`)로 바로 올렸을 때의 오류(위쪽은 실행한 명령). ch-standard·ch-private·ch-shared 모두 "HTTP 400 - This API is not supported for AAD accounts"가 출력된다. 프롬프트의 계정 부분은 가렸다.*

**실행한 스크립트** (준비 코드: [채널 403 글]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }})의 "공통 준비 코드")

```powershell
foreach ($c in $ch | Where-Object displayName -ne 'General') {
  $u = "$B/teams/$tid/channels/$($c.id)/filesFolder/content"
  try { Invoke-RestMethod -Method Put -Headers $h -Uri $u -ContentType 'text/plain' -Body 'x' | Out-Null; "OK $($c.displayName)" }
  catch { "$($c.displayName): HTTP $($_.Exception.Response.StatusCode.value__) - $(($_.ErrorDetails.Message | ConvertFrom-Json).error.message)" }
}
```

### 2. 먼저 확인할 것

400은 "권한이 없다"(403)가 아니라 "요청 형식이 받아들여지지 않는다"는 뜻이므로, 먼저 요청 경로를 의심했습니다.

| 순서 | 확인 | 결과 |
|---|---|---|
| 1 | 유형이 다른 세 채널에서 같은 400인가 | 세 채널 모두 같은 400 → 채널 유형이나 멤버십 문제가 아니라 **경로 문제** |
| 2 | 채널의 파일 폴더 정보(`filesFolder`)는 읽히는가 | 읽힘. 폴더가 들어 있는 드라이브의 `driveId`와 폴더 항목의 `itemId`를 얻을 수 있음 |
| 3 | 업로드 문서가 안내하는 경로는 무엇인가 | 드라이브와 항목을 지정하는 `PUT drives/{driveId}/items/{itemId}:/파일명:/content` (문서: driveItem 업로드) |

### 3. 시도와 결과

경로 자체가 지원되지 않는 것으로 보고, 채널마다 `filesFolder`를 조회해 driveId·itemId를 구한 뒤 드라이브 경로로 올렸습니다.

```powershell
foreach ($c in $ch) {
  $ff = Invoke-RestMethod -Headers $h -Uri "$B/teams/$tid/channels/$($c.id)/filesFolder"
  $u  = "$B/drives/$($ff.parentReference.driveId)/items/$($ff.id):/zz-test.txt:/content"
  try { Invoke-RestMethod -Method Put -Headers $h -Uri $u -ContentType 'text/plain' -Body 'zz-test' | Out-Null; "UPLOAD OK zz-test.txt -> $($c.displayName)" }
  catch { "UPLOAD $($c.displayName): $($_.Exception.Response.StatusCode.value__) ($($_.Exception.Response.ReasonPhrase)) $(($_.ErrorDetails.Message | ConvertFrom-Json).error.code)" }
}
```

*이 스크립트는 채널마다 파일 폴더의 driveId·itemId를 읽은 뒤 `PUT .../content`로 시험 파일을 올리고, 실패하면 HTTP 코드와 오류 코드만 출력합니다. 같은 파일명으로 다시 올리면 표준 채널과 General의 기존 zz-test.txt가 덮어써집니다.*

![채널별 업로드 결과]({{ "/assets/images/2026/10/m13-1-upload-result.png" | relative_url }})
*그림 2. 드라이브 경로로 올린 결과(위쪽은 실행한 명령, 아래는 출력). ch-standard와 General은 "UPLOAD OK zz-test.txt", 비공개(ch-private)와 공유(ch-shared)는 "403 (Forbidden) accessDenied"가 출력된다. 프롬프트의 계정 부분은 가렸다.*

- 표준 채널과 General은 성공했습니다. 400이 사라졌으므로 앞의 실패는 경로 때문이었습니다.
- 비공개·공유 채널은 이 경로에서도 막혔지만 이번에는 400이 아니라 **403 accessDenied**입니다. 오류의 종류가 바뀌었다는 것은 요청이 형식 단계는 통과했다는 뜻이고, 이후의 403은 멤버십이 아닌 토큰의 파일·사이트 범위 문제로 좁혀졌습니다([채널 403 글]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }})).
- 이 방식이 요구하는 Graph 권한은 문서에 따라 Files.ReadWrite, Files.ReadWrite.All, Sites.ReadWrite.All 중 하나입니다(문서: driveItem 업로드).
- **확인 불가**: 채널 경로(`filesFolder/content`)가 이 계정에서 지원되지 않는 정확한 이유. 시도: 세 채널 모두 같은 경로로 업로드 → 모두 같은 400. 사유: 응답 문구 외에 이유를 알려 주는 내용이 없음. 다음 방법: 문서가 안내하는 드라이브 경로(driveId·itemId)를 기준 방식으로 삼고 채널 경로는 쓰지 않음.

### 4. 대처·원복

- 업로드는 항상 `filesFolder`로 driveId·itemId를 먼저 구한 뒤 드라이브 경로로 올립니다.
- 경로를 잘못 지정해 시험하다 팀 문서함(General)에 `zz-x.txt`가 생겼습니다. 정리 목록에 넣었습니다.
- 같은 파일명으로 다시 올리면 기존 시험 파일이 덮어써집니다. 표준 채널과 General의 `zz-test*.txt`는 팀 삭제 때 함께 지웁니다.

### 5. 운영에서는 이렇게 판단한다

- 400과 403은 원인이 다릅니다. 400은 요청 형식·경로, 403은 권한·범위를 먼저 봅니다.
- 채널 유형별 폴더 주소를 추측해서 쓰지 말고, 채널마다 `filesFolder`로 실제 주소를 얻어 씁니다.
- 업로드 성공 여부는 응답 코드만으로 판단하지 않고 파일이 실제로 저장된 위치도 함께 확인합니다.

### 6. 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 조회 | 채널 경로 업로드 세 채널 모두 HTTP 400 "This API is not supported for AAD accounts"(그림 1) | Cloud Shell(Graph) |
| 조회 | 드라이브 경로 업로드: 표준·General 성공, 비공개·공유 403(그림 2) | Cloud Shell(Graph) |
| 문서 | 업로드 경로와 필요한 Graph 권한 | [Upload or replace the contents of a driveItem](https://learn.microsoft.com/graph/api/driveitem-put-content?view=graph-rest-1.0) |
| 문서 | 채널 파일 폴더 정보 조회 | [Get filesFolder](https://learn.microsoft.com/graph/api/channel-get-filesfolder?view=graph-rest-1.0) |

관련 글: [비공개·공유 채널 파일 403 — 멤버십인가 토큰 범위인가]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }}) · [Cloud Shell 토큰으로 되는 Graph 호출과 안 되는 호출]({{ "/m365/troubleshooting/cloud-shell-graph-token-scope/" | relative_url }}) · [응답은 403인데 파일이 생김]({{ "/m365/troubleshooting/upload-403-but-file-created/" | relative_url }})
