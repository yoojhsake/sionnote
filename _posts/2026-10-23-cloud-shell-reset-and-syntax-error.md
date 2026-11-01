---
title: "[Troubleshooting] Cloud Shell이 다시 시작되어 변수가 사라지거나, 붙여 넣은 명령이 구문 오류가 남"
date: 2026-10-23 10:35:00 +0900
categories: [m365, troubleshooting]
area: Graph·Cloud Shell·스크립트
seq: 2
tags: [Cloud Shell, PowerShell, ParserError, 세션 초기화]
excerpt: "다른 주소에 다녀오니 Cloud Shell 변수가 사라지고 붙여 넣은 명령은 ParserError. 셸 준비를 확인한 뒤 한 번에 붙여 넣습니다"
---

다른 주소에 다녀왔더니 Cloud Shell이 다시 시작되어 `$tk`·`$h` 변수가 사라졌고, 셸이 준비되기 전에 붙여 넣은 명령은 구문 오류(ParserError)가 났습니다. 준비 코드를 다시 실행하고, 셸이 준비된 것을 확인한 뒤 호출 묶음을 한 번에 붙여 넣으면 됩니다.

## 요약

- 탭 이동 때 세션이 초기화되고 시작 중 입력은 이어 붙어 해석됨
- ParserError면 권한이 아니라 입력 모양을 의심하고 프롬프트부터 확인
- 처음 입력이 어떤 모양으로 이어 붙었는지는 확인 불가

> 근거: 조회는 이 테넌트에서 직접 읽은 값, 문서는 Microsoft Learn입니다. 비공개 정보는 가렸습니다. 토큰도 게시하지 않았습니다.

---

## 전체 기록



### 1. 증상

- 사례 1: 다른 주소로 이동하면 Cloud Shell이 다시 시작되어 `$tk`(토큰), `$h`(헤더), `$B`(Graph 주소)가 사라지고 호출이 실패합니다.
- 사례 2: 셸 준비 전에 붙여 넣은 명령이 두 번 실행되거나 구문 오류가 났습니다.

### 2. 원인 및 분석

- 사례 1: 탭 이동 시 세션이 초기화되므로 변수가 없는 것이 정상입니다.
- 사례 2: 시작 중 입력이 이어 붙어 해석됩니다. `(Get-Date) clear`로 재현하니 ParserError가 났습니다(조회).

<details markdown="1">
<summary>확인 과정 자세히 보기 (그림 1장)</summary>

#### 짚어 본 것

1. 직전에 다른 주소로 이동했는가. 이동했다면 세션이 초기화되어 변수가 없는 것이 정상입니다.
2. 셸 프롬프트가 나타나기 전에 붙여 넣었는가. 준비 전 입력이면 두 번 실행되거나 구문 오류가 날 수 있습니다.
3. 오류 문구가 ParserError인가, 호출 응답 오류(HTTP 코드)인가. ParserError는 명령 모양의 문제이고, HTTP 코드는 호출의 문제입니다.

#### 오류를 다시 만들어 보기

구문 오류는 처음 겪은 순간을 다시 만들 수 없어, 명령이 끝난 뒤 공백만 두고 다른 단어가 붙는 경우를 만들어 봤습니다.

```powershell
(Get-Date) clear   # 명령이 끝난 뒤 공백만 두고 다른 단어가 붙으면 ParserError
```

![셸 시작 중 붙여 넣은 명령의 구문 오류]({{ "/assets/images/2026/10/m14-3-parse-error.png" | relative_url }})
*그림 1. 구문 오류 재현. 처음 겪은 상황(셸이 준비되기 전에 붙여 넣은 명령이 이어 붙음)은 같은 순간을 다시 만들 수 없어, 명령 뒤에 다른 글자가 바로 붙은 `(Get-Date) clear`를 입력해 같은 종류의 오류를 재현했습니다. 빨간 글씨로 ParserError(Unexpected token 'clear' in expression or statement)가 나옵니다. 계정 부분은 가렸습니다.*

결과는 ParserError(Unexpected token 'clear' in expression or statement)였습니다(그림 1, 조회). 한 명령 뒤에 다른 글자가 바로 이어 붙으면 같은 종류의 오류가 난다는 것을 확인했습니다.

셸 시작 중 붙여 넣은 입력이 실제로 어떤 모양으로 이어 붙었는지는 **확인 불가**입니다.

- 시도: 같은 종류의 이어 붙은 명령을 입력해 재현
- 사유: 처음 상황은 같은 순간을 다시 만들 수 없음
- 다음 방법: 같은 증상이 다시 나면 오류 화면 전체를 그대로 저장해 대조

</details>

### 3. 결론

탭 이동 → 세션 초기화 → 변수 없음 / 준비 전 붙여 넣기 → 입력이 이어 붙음 → ParserError·이중 실행

원복할 변경은 없습니다. 처음 입력이 어떤 모양으로 이어 붙었는지는 확인 불가입니다(같은 순간을 다시 만들 수 없음, 시도·다음 방법은 확인 과정).

### 4. 권고방안

1. 조치: 세션이 바뀌면 준비 코드([채널 403 글]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }})의 "공통 준비 코드")를 다시 실행하고, 프롬프트가 나타난 뒤 호출 묶음을 한 번에 붙여 넣습니다.
2. 확인: 변수를 못 찾으면 세션 초기화부터, ParserError면 권한이 아니라 입력 모양부터 봅니다. 결과 화면에 실행한 명령이 남도록 합니다.
3. 하지 말 것: 셸이 준비되기 전에 입력하지 않습니다.

관련 글: [Cloud Shell 토큰으로 되는 Graph 호출과 안 되는 호출]({{ "/m365/troubleshooting/cloud-shell-graph-token-scope/" | relative_url }}) · [비공개·공유 채널 파일 403: 멤버십인가 토큰 범위인가]({{ "/m365/troubleshooting/channel-upload-403-membership-or-scope/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (2건)</summary>

- 조회: 탭 이동 시 세션 초기화로 변수가 사라짐, 시작 중 붙여 넣으면 이중 실행·구문 오류
    - 출처: Cloud Shell 사용 중 관찰
- 조회: `(Get-Date) clear` 입력 시 ParserError(그림 1)
    - 출처: Cloud Shell(PowerShell)

</details>
