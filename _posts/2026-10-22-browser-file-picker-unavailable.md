---
title: "[Troubleshooting] 브라우저 파일 선택창을 쓸 수 없을 때"
date: 2026-10-22 10:10:00 +0900
categories: [m365, troubleshooting]
area: Teams·채널·파일
seq: 6
tags: [Teams, Graph, Cloud Shell, 파일 업로드, 파일 선택창]
excerpt: "파일 선택창을 쓸 수 없어 Cloud Shell의 Graph로 올렸더니 표준 채널은 201, 비공개·공유 채널은 403이었습니다."
---

Teams·SharePoint에 파일을 올리려는데 브라우저의 파일 선택 대화상자를 쓸 수 없었습니다. Cloud Shell에서 Graph `PUT .../content`로 시험 파일을 올렸고, 표준 채널은 201로 성공, 비공개·공유 채널은 403이었습니다.

## 요약

- 파일 선택창이 막힌 환경에서는 Graph 업로드 호출로 대신 올릴 수 있음
- 응답 코드만 믿지 말고 SharePoint 화면에서 저장 위치를 다시 봐야 함
- 직접 업로드와 Graph 업로드 결과가 같은지는 확인 불가

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다. 사이트 주소도 게시하지 않았습니다.

---

## 전체 기록

### 1. 증상

- Teams 파일 탭, SharePoint 업로드 버튼에서 파일 선택 대화상자가 열리지 않음(캡처할 화면 없음)

### 2. 원인 및 분석

(가) 실습 환경 제약이라 고칠 대상이 없고, Graph `PUT .../content`는 선택창 없이 올릴 수 있습니다(문서: driveItem 업로드).

(나) 채널별 `filesFolder`의 `driveId`, `itemId`로 `D3-test-<채널명>.txt`를 올린 결과:

| 채널 | Graph 응답 | SharePoint 화면에서 파일 |
|---|---|---|
| ch-standard | 201 성공 | 있음(팀 사이트의 ch-standard 폴더) |
| ch-private | **403** | 있음(별도 사이트) |
| ch-shared | **403** | 있음(별도 사이트) |

<details markdown="1">
<summary>확인 과정 자세히 보기 (그림 2장)</summary>

#### 우회로를 찾기 전에 따져 본 것

1. 같은 증상이 다른 방법에서도 나는가. 파일 선택 대화상자가 필요한 방법은 모두 막힙니다.
2. 파일 선택이 필요 없는 방법이 있는가. 위 (가)의 `PUT .../content`.
3. Cloud Shell에서 Graph를 호출할 수 있는가. 팀 목록, 채널 목록, 채널 파일 폴더 정보를 읽을 수 있는지 봅니다.

#### 올려 본 결과

![채널별 시험 파일 업로드 결과 출력]({{ "/assets/images/2026/10/m13-1-upload-result.png" | relative_url }})
*그림 1. 같은 방식으로 다시 올린 결과(파일명 zz-test.txt). 첫 시험(D3-test-<채널명>.txt)의 출력 화면은 남아 있지 않습니다. Cloud Shell에서 채널마다 시험 파일을 올린 결과. 표준 채널과 General은 `UPLOAD OK`, 비공개·공유 채널은 `403 (Forbidden) accessDenied`. 계정이 보이던 프롬프트 부분은 가렸습니다.*

![채널별 SharePoint 문서 화면]({{ "/assets/images/2026/10/d3-sharepoint-files.png" | relative_url }})
*그림 2. 같은 시험 뒤 SharePoint 문서 화면. 위: 팀 사이트의 ch-standard 폴더, 가운데: 별도 사이트(ch-private), 아래: 별도 사이트(ch-shared). 사용자 이름은 가렸습니다.*

아래는 같은 방식의 스크립트입니다. 준비 코드와 업로드 부분이고, 팀 이름 Practice-Team-01은 시험용으로 만든 팀입니다.

```powershell
# 공통 준비 코드: Cloud Shell(PowerShell)의 Azure 로그인 세션으로 Graph 토큰을 받아 호출
$tk = [System.Net.NetworkCredential]::new('', (Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com').Token).Password
$h  = @{ Authorization = "Bearer $tk" }
$B  = 'https://graph.microsoft.com/v1.0'
$tid = (Invoke-RestMethod -Headers $h -Uri "$B/me/joinedTeams").value | Where-Object displayName -eq 'Practice-Team-01' | Select-Object -ExpandProperty id
$ch  = (Invoke-RestMethod -Headers $h -Uri "$B/teams/$tid/allChannels").value
```

```powershell
foreach ($c in $ch) {
  $ff = Invoke-RestMethod -Headers $h -Uri "$B/teams/$tid/channels/$($c.id)/filesFolder"
  $u  = "$B/drives/$($ff.parentReference.driveId)/items/$($ff.id):/zz-test.txt:/content"
  try { Invoke-RestMethod -Method Put -Headers $h -Uri $u -ContentType 'text/plain' -Body 'zz-test' | Out-Null; "UPLOAD OK zz-test.txt -> $($c.displayName)" }
  catch { "UPLOAD $($c.displayName): $($_.Exception.Response.StatusCode.value__) ($($_.Exception.Response.ReasonPhrase)) $(($_.ErrorDetails.Message | ConvertFrom-Json).error.code)" }
}
```

*이 스크립트는 채널마다 파일 폴더의 driveId·itemId를 읽은 뒤 `PUT .../content`로 시험 파일을 올리고, 실패하면 HTTP 코드와 오류 코드만 출력합니다. 처음 시험 때 입력한 명령 원문은 복구하지 못해, 같은 방식으로 정리한 형태입니다(파일명은 재실행판의 zz-test.txt).*

</details>

### 3. 결론

`선택창 불가 → Graph PUT 대체 → 비공개·공유 403, 파일은 셋 다 있음`

비공개·공유 채널의 403은 토큰 범위와 관련이 있습니다([비공개·공유 채널 파일 403]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }}) 참고). 직접 업로드와의 차이는 확인 불가입니다.

<details markdown="1">
<summary>확인 불가 항목 펼쳐 보기 (1건)</summary>

- **사람이 Teams에서 직접 올리는 경우와 Graph 업로드의 결과가 같은지**: 확인 불가
    - 시도: 브라우저 파일 선택창으로 직접 업로드.
    - 사유: 파일 선택창을 쓸 수 없어 직접 업로드를 시도하지 못함.
    - 다음 방법: 파일 선택창을 쓸 수 있는 환경에서 같은 채널에 직접 올려 응답과 저장 위치를 비교.

</details>

### 4. 권고방안

1. 조치: Graph 호출로 대체하고 방법을 바꿨다는 점을 결과와 함께 적습니다. 시험 파일(zz-test*.txt 등)은 팀 삭제 때 지웁니다(정리 목록).
2. 조치 후 확인: 응답 코드가 아니라 SharePoint 화면의 저장 위치로 판단합니다.
3. 하지 말아야 할 것: 자동화 결과를 사람이 올린 결과와 같다고 단정하기

관련 글: [비공개·공유 채널 파일 403]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }}) · [응답은 403인데 파일이 만들어졌을 때]({{ "/m365/troubleshooting/upload-403-but-file-created/" | relative_url }}) · [Teams 저장 구조]({{ "/m365/d3-teams-storage/" | relative_url }}) · [Cloud Shell에서 Graph 호출]({{ "/m365/troubleshooting/cloud-shell-graph-token-scope/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (4건)</summary>

- 문서: 파일 업로드(`PUT .../content`) 방식과 필요한 권한
    - 출처: [Upload or replace the contents of a driveItem](https://learn.microsoft.com/graph/api/driveitem-put-content?view=graph-rest-1.0)
- 문서: 채널의 파일 폴더 정보 조회
    - 출처: [Get filesFolder](https://learn.microsoft.com/graph/api/channel-get-filesfolder?view=graph-rest-1.0)
- 조회: 표준 201, 비공개·공유 403, 세 채널의 파일이 SharePoint 화면에 존재
    - 출처: Cloud Shell(Graph), SharePoint 화면
- 확인 불가: 직접 업로드와 Graph 업로드의 차이
    - 시도, 사유, 다음 방법은 3절 결론

</details>
