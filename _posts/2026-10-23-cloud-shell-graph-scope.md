---
title: "[M365·Azure] 14 Cloud Shell에서 Graph를 호출할 때 되는 것과 안 되는 것 (토큰 범위 정리, 전체 기록)"
date: 2026-10-23 10:30:00 +0900
categories: [m365, troubleshooting]
tags: [Cloud Shell, Graph, 토큰, "403", 전체 기록]
excerpt: "Cloud Shell의 Azure 로그인으로 받은 Graph 토큰으로 읽은 것과 읽지 못한 것을 나누고, 보안 설정을 바꾸지 않고 쓸 수 있는 방법과 막혔을 때의 선택지를 정리한 기록"
---

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell에서 직접 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못함(시도 방법·사유 병기). 토큰·ID·계정은 게시하지 않았습니다.

## 1. 방법

Azure Cloud Shell(PowerShell)에서 이미 로그인된 Azure 세션으로 Graph용 액세스 토큰을 받아(`Get-AzAccessToken`) Graph 주소를 호출했습니다. 별도 로그인이나 보안 설정 변경 없이 쓸 수 있는 방법이라 이번 실습에서 사용했습니다.

## 2. 결과

| 호출 | 결과 |
|---|---|
| 내가 가입한 팀 목록(`joinedTeams`) | 성공 |
| 사용자 목록 | 성공 |
| 서비스 사용자 목록 | 성공 |
| 팀 > 채널 목록(`allChannels` 포함) | 성공 |
| 채널 파일 폴더 정보 | 표준 채널 성공, 비공개·공유 채널은 403 ([13 글]({{ "/m365/troubleshooting/channel-upload-403-repro/" | relative_url }})) |
| 내 OneDrive(`/me/drive`) | HTTP 403 (처음에는 OneDrive가 없어서라고 추정했으나 나중에 OneDrive가 존재함을 확인해 정정, §4 참고) |
| 조건부 액세스 정책 목록 | HTTP 403 (읽기 권한 부족, 최소 읽기 역할은 확인 불가) |

![Graph로 읽은 팀 목록]({{ "/assets/images/2026/10/m14-2-group-list.png" | relative_url }})
*그림 1. 위쪽 세 줄은 토큰·헤더·주소 변수를 만드는 줄이고, 네 번째 줄이 `joinedTeams`를 호출해 팀 표(displayName, id)를 출력한다. 호출이 성공해 팀 8개가 나온다. 테넌트 이름과 같은 팀·다른 조직 이름 팀의 이름, id 열 전체, 계정 이름은 가렸다.*

**실행한 스크립트**

```powershell
# 1~3줄: 토큰·헤더·주소 변수 (그림 1의 위쪽 세 줄)
$tk = [System.Net.NetworkCredential]::new('', (Get-AzAccessToken -ResourceUrl 'https://graph.microsoft.com').Token).Password
$h  = @{ Authorization = "Bearer $tk" }
$B  = 'https://graph.microsoft.com/v1.0'
(Invoke-RestMethod -Headers $h -Uri "$B/me/joinedTeams").value | Select-Object displayName,id | Format-Table -AutoSize
```

## 3. 막혔던 일과 해결

- **채널 파일 업로드 경로**: 처음에 채널 경로로 바로 올리려다 "AAD 계정에서는 지원되지 않는 요청"이라는 400이 났습니다. 채널의 파일 폴더 정보에서 `driveId`와 `itemId`를 먼저 구한 뒤 `PUT drives/{driveId}/items/{itemId}:/파일명:/content`로 올리자 성공했습니다.
- **탭을 이동하면 Cloud Shell이 다시 시작**: 다른 주소로 이동하면 세션이 초기화되어 변수가 사라집니다. 매번 변수를 다시 정의해야 하므로 호출 묶음을 한 번에 붙여 넣는 편이 안전합니다.
- **시작 중 입력**: 셸이 준비되기 전에 명령을 붙여 넣으면 두 번 실행되거나 구문 오류가 났습니다. 준비된 것을 확인한 뒤 입력합니다.

![채널 경로로 바로 올렸을 때의 400 오류]({{ "/assets/images/2026/10/m14-1-badrequest.png" | relative_url }})
*그림 2. 채널 경로(`filesFolder/content`)로 바로 올렸을 때의 오류(위쪽은 실행한 명령). ch-standard·ch-private·ch-shared 모두 "HTTP 400 - This API is not supported for AAD accounts"가 출력된다. 프롬프트의 계정 부분은 가렸다.*

**실행한 스크립트** (준비 코드: [13 글]({{ "/m365/troubleshooting/channel-upload-403-repro/" | relative_url }})의 "공통 준비 코드")

```powershell
foreach ($c in $ch | Where-Object displayName -ne 'General') {
  $u = "$B/teams/$tid/channels/$($c.id)/filesFolder/content"
  try { Invoke-RestMethod -Method Put -Headers $h -Uri $u -ContentType 'text/plain' -Body 'x' | Out-Null; "OK $($c.displayName)" }
  catch { "$($c.displayName): HTTP $($_.Exception.Response.StatusCode.value__) - $(($_.ErrorDetails.Message | ConvertFrom-Json).error.message)" }
}
```

해결은 같은 글의 방식입니다. 채널의 파일 폴더 정보에서 `driveId`·`itemId`를 읽은 뒤 `PUT drives/{driveId}/items/{itemId}:/파일명:/content`로 올리면 표준 채널은 성공합니다.

![셸 시작 중 붙여 넣은 명령의 구문 오류]({{ "/assets/images/2026/10/m14-3-parse-error.png" | relative_url }})
*그림 3. 구문 오류 재현. 처음 겪은 상황(셸이 준비되기 전에 붙여 넣은 명령이 이어 붙음)은 같은 순간을 다시 만들 수 없어, 명령 뒤에 다른 글자가 바로 붙은 `(Get-Date) clear`를 입력해 **같은 종류의 오류**를 재현했다. 빨간 글씨로 ParserError(Unexpected token 'clear' in expression or statement)가 나온다. 계정 부분은 가렸다.*

**재현에 쓴 명령**

```powershell
(Get-Date) clear   # 명령이 끝난 뒤 공백만 두고 다른 단어가 붙으면 ParserError
```

## 4. 판단

- 403이 났을 때 "권한 없음"과 "대상이 없음"을 구분합니다. `/me/drive`의 403은 OneDrive가 없어서일 것이라 추정했지만, 10/23 오후에 OneDrive 웹을 다시 열었더니 **OneDrive가 존재했습니다**(Meetings·Recordings 폴더 확인). 그러므로 이 403은 "대상이 없음"이 아니라 토큰에 Files 범위가 없는 쪽으로 읽는 것이 맞아 보입니다. 다만 Files 범위 토큰으로 `/me/drive`가 열리는 것은 530035 때문에 아직 확인하지 못했습니다(**확인 불가**, 월요일 재시도).
- 읽기 역할이 부족한 항목은 화면(GUI)으로 대체해 읽었습니다(조건부 액세스 정책 0건은 GUI에서 확인).
- 토큰 범위를 넓히려고 역할을 부여받거나 보안 설정을 바꾸는 일은 하지 않았습니다. 별도 승인이 필요한 일이기 때문입니다.

## 5. 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 조회 | 위 표의 호출 결과 | Cloud Shell(Graph) |

## 담당별 기록

이 글은 유재홍이 실습·측정한 내용입니다. 같은 주제에서 대원·현준이 맡은 부분은 각자 직접 채웁니다(칸만 마련).

| 담당 | 기록 | 상태 |
|---|---|---|
| 유재홍 | 이 글의 실습·측정·정리 | 작성함 |
| 대원 | (대원이 맡은 부분을 여기에 직접 작성) | 작성 대기 |
| 현준 | (현준이 맡은 부분을 여기에 직접 작성) | 작성 대기 |
