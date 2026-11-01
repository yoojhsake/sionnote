---
title: "[Troubleshooting] 계정을 막았는데 퇴사자가 여전히 메일·파일에 접근할 때"
date: 2026-11-01 09:06:00 +0900
categories: [iam, troubleshooting]
area: 로그인·권한
seq: 6
tags: [Troubleshooting, Entra ID, 퇴사자, 세션 해지, 토큰, CAE, 하이브리드, PHS]
excerpt: "계정을 사용 안 함으로 바꿔도 이미 받은 토큰·세션과 동기화 주기 때문에 접근이 잠시 남는 이유와, 즉시 끊는 순서(사용 안 함 → 세션 해지 → 기기 사용 안 함)"
---

> Microsoft Learn 공식 문서(2026-11-01 확인)를 기준으로 쓴 대처 가이드입니다. 특정 테넌트에서 재현한 기록은 아닙니다. 개념은 [Entra ID 핵심 개념 — 인증 편]({{ "/iam/entra-id-authentication/" | relative_url }})을 함께 보세요. 오류 번호와 HTTP 상태 코드가 낯설면 [오류 코드 읽는 법]({{ "/iam/entra-id-error-codes/" | relative_url }})을 먼저 보세요.

## 요약

- **증상**: 퇴사자 계정을 막았는데 휴대폰 메일 앱이나 열려 있던 브라우저에서 한동안 계속 접근됨
- **원인**
    - 이미 발급된 **액세스 토큰**(기본 60~90분)·앱 **세션 쿠키**가 남아 있음
    - 하이브리드면 AD에서 막은 상태가 **아직 동기화 안 됨**
- **대처**: 사용 안 함 → 세션 해지(Revoke sessions) → 기기 사용 안 함 순서. 하이브리드는 사내 AD에서 막고 동기화를 한 번 더 실행
- **알아 둘 것**: Exchange·SharePoint·Teams는 CAE(연속 액세스 평가)로 계정 사용 안 함·세션 해지를 몇 분 안에 반영. 그 밖의 앱은 토큰·세션이 끝날 때까지 남을 수 있음

---

## 전체 내용

### 1. 증상

인사팀 요청으로 퇴사자 계정을 오전 10시에 **사용 안 함**으로 바꿨습니다. 그런데 퇴사자의 개인 휴대폰에 설정된 메일 앱이나, 회사 SaaS 앱의 열려 있던 브라우저 탭에서 한동안 접근 기록이 남습니다.

### 2. 왜 바로 안 끊기나

- **액세스 토큰**: Entra ID가 발급하는 액세스 토큰은 기본 60~90분(평균 75분) 사이로 유효. 앱은 만료되면 새로 받으려 하고, 이때 막힘. CAE를 지원하는 앱·클라이언트는 더 긴 토큰을 받는 대신 중요 이벤트가 생기면 무효화됨(목표는 몇 분, 최대 15분 지연 가능). 조건부 액세스가 없는 테넌트의 Teams·M365 클라이언트는 기본 2시간, CAE 세션은 최대 28시간
- **앱 세션 쿠키**: 브라우저 앱은 Entra 로그인 뒤 앱 자체 세션을 발급. Entra ID는 앱이 발급한 세션을 직접 끊을 수 없음. 앱이 다시 Entra로 보내기 전까지 남을 수 있음
- **CAE**: Exchange Online·SharePoint Online·Teams 등은 계정 사용 안 함·삭제, 암호 변경, 세션 해지, 높은 사용자 위험 이벤트를 받아 몇 분 안에 접근을 끊음(CAE를 지원하는 클라이언트 조합에서)
- **하이브리드 동기화**: Entra Connect Sync는 기본 30분마다 동기화. 사내 AD에서 막은 상태가 클라우드에 반영되기 전까지는 클라우드 로그인이 될 수 있음

### 3. 즉시 끊는 순서

GUI(Entra 관리 센터):

1. **사용 안 함**: Entra ID > Users > All users > 해당 사용자 > **Account status** 옆 Edit > Properties에서 Account enabled(계정 사용) 해제 > Save
2. **세션 해지**: 사용자 개요 화면 위쪽의 **Revoke sessions(세션 해지)**. 모든 리프레시 토큰이 무효화되어 다시 로그인해야 함
3. **기기 사용 안 함**: Entra ID > Devices > All devices에서 해당 사용자의 기기를 찾아 **Disable**(문서는 이 단계를 PowerShell로 안내하므로 아래 스크립트도 함께 제시)
4. **인증 방법 정리**: 사용자 > Authentication methods에서 등록된 방법 제거(재입사·계정 재사용 사고 방지)
5. 필요하면 라이선스 회수, 메일 전달·사서함 보존은 회사 규정대로

**하이브리드라면** 문서 권장 순서대로 사내 AD에서 먼저 계정을 **사용 안 함**으로 바꾸고 암호를 두 번 재설정합니다(pass-the-hash 위험 완화, 계정이 침해되지 않았다고 확신하면 한 번도 가능). 그다음 동기화를 기다리지 말고 Entra에서도 1~4번을 바로 실행하고, 필요하면 델타 동기화를 한 번 돌려 상태를 맞춥니다.

GUI로 여러 명을 처리하기 어렵다면, 문서에 나온 Microsoft Graph PowerShell 순서를 그대로 쓸 수 있습니다. 아래는 한 명 기준 전체 스크립트입니다.

```powershell
# 필요한 모듈: Microsoft.Graph (Users, Users.Actions, Identity.DirectoryManagement)
# 필요 역할: 사용자 관리자 이상(관리자 계정이면 권한 있는 인증 관리자), 기기는 클라우드 디바이스 관리자
# Device.ReadWrite.All은 위임 권한이 없어 대화형 로그인에 쓰지 않음
Connect-MgGraph -Scopes "User.ReadWrite.All","Directory.AccessAsUser.All"

$upn  = "leaver@contoso.com"   # 퇴사자 UPN
$User = Get-MgUser -Filter "userPrincipalName eq '$upn'"

# 1) 계정 사용 안 함
Update-MgUser -UserId $User.Id -AccountEnabled:$false

# 2) 리프레시 토큰·세션 해지
Revoke-MgUserSignInSession -UserId $User.Id

# 3) 등록된 기기 사용 안 함
Get-MgUserRegisteredDevice -UserId $User.Id -All | ForEach-Object {
    Update-MgDevice -DeviceId $_.Id -AccountEnabled:$false
}

# 확인
Get-MgUser -UserId $User.Id -Property AccountEnabled,SignInSessionsValidFromDateTime |
    Select-Object AccountEnabled, SignInSessionsValidFromDateTime
```

```powershell
# (하이브리드) 사내 AD — 도메인 관리 권한이 있는 PC에서 (ActiveDirectory 모듈)
$sam = "leaver"   # 퇴사자 sAMAccountName
Disable-ADAccount -Identity $sam
# 암호 두 번 재설정 (예시 문자열 대신 매번 무작위 값 사용)
1..2 | ForEach-Object {
    $pw = -join ((33..126) | Get-Random -Count 24 | ForEach-Object {[char]$_})
    Set-ADAccountPassword -Identity $sam -Reset -NewPassword (ConvertTo-SecureString $pw -AsPlainText -Force)
}
```

```powershell
# (하이브리드) Entra Connect Sync 서버에서 상태를 맞추는 델타 동기화
Import-Module ADSync
Start-ADSyncSyncCycle -PolicyType Delta
```

> 스크립트는 문서의 명령을 한 사람 처리용으로 묶은 것입니다. 실행 결과(성공 여부)는 이 글에서 재현하지 않았습니다. 운영에 쓰기 전에 시험 계정으로 먼저 확인하세요.

### 4. 해결 확인

- 로그인 로그에서 퇴사자 계정의 새 로그인 시도가 **50057(UserDisabled)** 등으로 실패하는지 봅니다.
- 사용자 속성의 SignInSessionsValidFromDateTime이 세션 해지 시각으로 바뀌었는지 확인합니다.
- 자체 세션을 쓰는 SaaS 앱은 그 앱의 관리 화면에서 세션을 따로 끊어야 할 수 있습니다.

### 5. 예방

- 퇴사 처리 체크리스트에 **세션 해지**를 반드시 넣습니다. "사용 안 함"만으로는 즉시 차단이 보장되지 않습니다.
- ID Governance가 있다면 **Lifecycle Workflows**로 퇴사일에 이 순서를 자동화할 수 있습니다.

## 근거 자료

- 하이브리드 차단 순서(AD 사용 안 함 → 암호 두 번 재설정 → Entra 차단), 앱 세션 토큰, 하이브리드 사용자 차단 순서(PowerShell): [Revoke user access in Microsoft Entra ID](https://learn.microsoft.com/entra/identity/users/users-revoke-access)
- 액세스 토큰 기본 수명 60~90분: [Access tokens in the Microsoft identity platform](https://learn.microsoft.com/entra/identity-platform/access-tokens)
- CAE 중요 이벤트, 지원 서비스·클라이언트: [Continuous access evaluation](https://learn.microsoft.com/entra/identity/conditional-access/concept-continuous-access-evaluation)
- Entra Connect Sync 기본 30분, 수동 델타 동기화: [Microsoft Entra Connect Sync: Scheduler](https://learn.microsoft.com/entra/identity/hybrid/connect/how-to-connect-sync-feature-scheduler)
- 50057 UserDisabled: [Microsoft Entra authentication and authorization error codes](https://learn.microsoft.com/entra/identity-platform/reference-error-codes)
