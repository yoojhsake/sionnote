---
title: "[Troubleshooting] 하이브리드 조인 후 AzureAdPrt가 NO로 나올 때"
date: 2026-11-04 09:30:00 +0900
categories: [iam, troubleshooting]
area: 하이브리드 동기화·에이전트
seq: 3
tags: [Troubleshooting, 하이브리드 조인, PRT, AADSTS50057, dsregcmd, 장치 동기화, 사용자 동기화]
excerpt: "조인은 성공했는데 사용자 로그인 뒤에도 AzureAdPrt가 NO였음. 로그인한 계정이 동기화 범위 밖이었거나, AD에서 막 켠 계정이 Entra에서는 아직 비활성이어서(AADSTS50057) 생긴 결과였다"
toc: true
---

하이브리드 조인이 끝난 PC에서 로그인한 뒤 `dsregcmd /status`의 AzureAdPrt가 NO로 나왔습니다. 도메인 관리자 계정은 동기화 범위 밖이어서, 테스트 계정은 AD에서 켠 직후 Entra에서는 계정이 아직 비활성이어서 NO였고, 범위 안 계정이 Entra에서 활성화된 뒤 다시 로그인하자 YES가 됐습니다.

## 요약

- PRT는 조인 뒤 사용자가 로그인할 때 받으며, 조인 직후 NO는 정상일 수 있음
- 로그인 사용자가 Entra에 없거나 비활성이면 PRT가 안 나오며 오류 코드는 SSO State에 찍힘
- AD에서 계정을 켠 뒤에는 Entra가 반영될 때까지 기다리거나 요청 시 프로비전으로 앞당겨야 함

> 근거 표기: 조회 = 이 랩에서 직접 읽은 값 · 문서 = Microsoft Learn · 확인 불가 = 시도했지만 확인하지 못한 값(방법·사유 병기). 테넌트 ID·도메인·계정 등 비공개 정보는 가리거나 게시하지 않았습니다.

---

## 전체 기록

### 1. 증상

- 조인한 PC에서 AzureAdJoined와 DomainJoined가 YES, DeviceAuthStatus가 SUCCESS인데 AzureAdPrt는 NO(조회)
- 도메인 관리자 계정(UPN이 .local, OU=Admins)으로 로그인했을 때 NO(조회)
- 테스트 계정(OU=CloudSync)으로 로그인했을 때 NO였고, SSO State에 오류가 표시됨(조회)

### 2. 원인 및 분석

PRT는 조인된 장치에서 사용자가 로그인할 때 Entra가 발급하는 토큰입니다(문서). 기대값은 로그인한 사용자가 Entra에도 활성 계정으로 있고 그 계정으로 토큰을 받는 것입니다.

<details markdown="1">
<summary>확인 과정 자세히 보기</summary>

#### 사례 1: 동기화 범위 밖 관리자 계정

도메인 관리자 계정은 OU=Admins 아래에 있고 UPN이 .local 접미사였습니다. 이 OU는 Connect Sync(ConnectSync OU)와 Cloud Sync(CloudSync OU) 어느 쪽 범위에도 없습니다(조회). 그래서 Entra에 대응하는 사용자가 없을 것으로 추정했지만, 포털에서 이 사용자의 존재 여부는 확인하지 않았습니다. 이 사례는 오류 출력까지 읽지 못해 추정입니다.

#### 사례 2: 테스트 계정

처음에는 테스트 계정이 AD에서 비활성이었습니다(조회). 비밀번호 없이 만들어 둔 계정이라 로컬 로그인이 막혔고, 암호를 재설정하고 활성화하자 로그인은 됐습니다. 그러나 PRT는 NO였고 SSO State가 다음 오류를 보여 줬습니다(조회).

```text
Attempt Status          : 0xc0000072
Server Error Code       : invalid_grant
Server Error Description: AADSTS50057: The user account is disabled.
```

AD에서 활성화한 변경이 Entra에는 아직 반영되지 않아 Entra 쪽 계정이 비활성이었던 것입니다. 이 시도는 같은 오류로 두 번 확인됐습니다(5분 간격).

#### 앞당겨서 해결

- 포털의 Cloud sync 구성에서 **요청 시 프로비전 → 사용자 탭**에 계정의 고유 이름(DN)을 넣고 프로비전했습니다. 화면에는 오류 문구가 떴지만 사용자는 반영됐습니다(조회).
- **프로비전 다시 시작**으로 전체를 다시 돌렸습니다.
- 두 PC에서 로그아웃 후 다시 로그인하자 AzureAdPrt가 YES가 됐고, 한 PC에서는 갱신 시각도 함께 표시됐습니다(조회).

**사용한 명령** — 각 PC의 PowerShell에서 PRT 항목과 실패 원인을 읽었습니다.

```powershell
dsregcmd /status | Select-String 'AzureAdPrt |AzureAdPrtUpdateTime|AzureAdPrtExpiryTime|AzureAdPrtAuthority'
dsregcmd /status | Select-String -Pattern 'SSO State' -Context 0,22   # 실패 원인까지 출력
```

#### UPN 접미사

테스트 계정의 AD UPN은 처음에 .local이었고, 테넌트 도메인으로 바꾼 뒤에 PRT가 YES가 됐습니다(조회). 두 변경이 같은 시점에 이뤄져서 UPN 변경이 꼭 필요했는지는 따로 확인하지 못했습니다.

</details>

### 3. 결론

로그인 사용자가 Entra에서 사용 가능한 계정이 아님(동기화 범위 밖이거나 비활성 상태가 아직 반영 안 됨) → 토큰 요청이 AADSTS50057로 거부 → AzureAdPrt NO → 계정이 활성화된 뒤 재로그인에서 YES.

확인 불가가 둘 있습니다. 하나는 UPN을 바꾸지 않았다면 PRT가 나왔을지(시도: 변경 전후만 비교, 사유: 두 변경이 같이 이뤄짐)이고, 다른 하나는 관리자 계정이 Entra에 있는지(시도: 범위 확인만, 사유: 포털에서 해당 사용자를 검색하지 않음)입니다.

### 4. 권고방안

1. `dsregcmd /status`에서 SSO State의 Server Error Description을 먼저 읽습니다. 계정이 비활성(AADSTS50057)인지 존재하지 않는지를 구분해 줍니다.
2. AD에서 계정을 켠 뒤에는 Cloud Sync는 요청 시 프로비전, Connect Sync는 Delta 동기화로 앞당긴 다음 재로그인합니다. 다시 로그인하기 전에 포털에서 사용자의 활성 상태를 보면 시간을 아낄 수 있습니다.
3. 조인 직후의 NO를 오류로 단정하지 마세요. PRT는 로그인 사용자가 있어야 생기므로, 사용자 로그인 뒤에 확인합니다.

관련 글: [Cloud Sync로 하이브리드 조인 구성하기]({{ "/iam/hybrid-join-cloud-sync/" | relative_url }}) · [AD 조인·하이브리드 조인·Entra 조인 비교 실측]({{ "/iam/join-types-comparison/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (3건)</summary>

- **문서**: 장치 진단 항목과 SSO State 확인
    - 출처: [Troubleshoot devices by using the dsregcmd command](https://learn.microsoft.com/entra/identity/devices/troubleshoot-device-dsregcmd)
- **조회**: SSO State 오류(0xc0000072, invalid_grant, AADSTS50057), AD 계정 Enabled=False와 UPN, OU 위치
    - 출처: sionnote-cl11 (dsregcmd /status), sionnote-ad01 (Get-ADUser)
- **조회**: 요청 시 프로비전과 프로비전 다시 시작 뒤 PRT YES와 갱신 시각
    - 출처: sionnote-cl10, sionnote-cl11 (2026-11-04)

</details>
