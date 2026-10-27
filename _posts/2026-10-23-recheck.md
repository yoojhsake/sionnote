---
title: "[M365·Azure] 11 10/23 재확인 — '확인 불가'로 남긴 항목을 다시 시도한 기록 (전체 기록)"
date: 2026-10-23 10:00:00 +0900
categories: [m365]
tags: [M365·Azure, 재확인, 확인 불가, Elevate access, 그룹 라이선스, 전체 기록]
excerpt: "10/22까지 확인 불가로 남긴 항목을 직접 다시 시도해 값으로 바꾼 것과, 끝내 확인하지 못한 것(시도 방법·사유)을 표로 정리한 기록. 변경 4건과 원복·정리 방법 포함"
---

수행일은 2026-10-23(금)입니다. 10/22까지 "확인 불가"로 남긴 항목은 대부분 "메뉴는 열 수 있었는데 시도하지 않은 것"이었습니다. 그래서 개발용 샌드박스(개인 환경)에서 **삭제와 비용이 드는 일을 뺀 변경은 직접 해 보는 방식**으로 다시 확인했습니다.

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell에서 직접 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못함(시도 방법·사유 병기). 테넌트 ID·구독 ID·도메인·계정·사용자 이름은 게시하지 않았습니다.

## 1. 이 글의 규칙

"확인 불가"는 **빈칸이 아니라 기록**입니다. 확인하지 못한 항목에는 아래 세 가지를 반드시 함께 적습니다.

1. 시도한 방법
2. 막힌 이유
3. 다음에 확인할 방법(또는 확인 사항으로 남김)

이렇게 적어 두면 이후에 다른 사람이 같은 방법을 반복하지 않고, 막힌 이유를 풀어서 다시 시도할 수 있습니다.

## 2. 변경한 것 (4건)

| 변경 | 내용 | 원복 방법 |
|---|---|---|
| Planner 계획 생성 | Plan MC-Tracking, Bucket MC-Bucket-01 생성 성공 | 팀을 삭제하면 함께 삭제됨(삭제는 하지 않음) |
| 리소스 공급자 등록 | Microsoft.OperationalInsights, Microsoft.Insights를 Registered로 | 구독 > 리소스 공급자에서 등록 취소(선택, 비용 없음) |
| 시험 사용자 부서 변경·원복 | 부서 변경 → 동적 그룹 가입 → 원복 (원복 10:12, 감사 로그) | 이미 원복함 |
| 시험 파일 업로드 | 채널 파일 폴더에 zz-test*.txt 추가 | 팀 삭제 시 함께 삭제 |
| 시험 사용자 부서 변경·원복(저녁 재측정) | 부서 Practice02 → 비움 (12:29~12:30 UTC), 비워진 것을 스크립트로 확인 | 이미 원복함 |
| 팀 일정 추가 | 팀(그룹) 캘린더에 zz-test-team-event-r2(10/28 11:00) 생성 | 팀 삭제 시 함께 삭제 |
| 시험 파일 정리 대상 | 표준 채널 폴더·팀 문서함 루트에 생긴 zz-x.txt, 팀 문서함의 ch-private·ch-shared 폴더(경로를 잘못 지정한 시험으로 생김) | 팀 삭제 시 함께 삭제 |

삭제는 영구 삭제에 해당해 하지 않았고, 실습을 마무리할 때 정리할 항목으로 남겼습니다.

![Planner에서 만든 MC-Tracking 계획]({{ "/assets/images/2026/10/m11-1-planner-plan.png" | relative_url }})
*그림 1. Planner에서 만든 계획 MC-Tracking의 보드 화면. 버킷 MC-Bucket-01이 보이고, 왼쪽 "내 플랜" 아래 계획이 만들어져 있다(10/22에는 만들지 않은 상태). 계정 표시는 가렸다.*

![리소스 공급자 등록 확인]({{ "/assets/images/2026/10/m11-2-resource-provider.png" | relative_url }})
*그림 2. Cloud Shell에서 두 리소스 공급자의 등록 상태를 읽은 화면(10/23 저녁 재조회, 위쪽은 실행한 명령). Microsoft.OperationalInsights와 microsoft.insights가 모두 Registered이다. 10/23 낮에 NotRegistered였던 microsoft.insights를 Register-AzResourceProvider로 등록한 직후의 Registering 화면은 이번에 다시 만들지 않았고(되돌려 등록 취소하는 변경이 필요해서), 처음 값과 변경 과정은 글 본문 표에 적었다. 계정 부분은 가렸다.*

**실행한 스크립트** (읽기 전용. 등록할 때는 `Register-AzResourceProvider -ProviderNamespace microsoft.insights`를 썼습니다)

```powershell
'Microsoft.OperationalInsights','microsoft.insights' | ForEach-Object { Get-AzResourceProvider -ProviderNamespace $_ } |
  Select-Object ProviderNamespace, RegistrationState -Unique | Format-Table -AutoSize
```

## 3. 다시 확인해서 값이 나온 것

| 항목 | 10/22까지 | 10/23 결과 | 근거 |
|---|---|---|---|
| 관리 그룹 설정 | 조회 시 HTTP 403 | 기본 관리 그룹 Tenant Root Group, 계층 보호 Off ([트러블슈팅 글]({{ "/m365/troubleshooting/mg-settings-403-elevate-refresh/" | relative_url }})) | 조회 |
| 리소스 공급자 | 두 개 모두 NotRegistered | 두 개 모두 Registered | 조회 |
| Planner Plan·Bucket 생성 | 하지 않음 | 생성 성공 | 조회 |
| 라이선스 18/25 vs 20/25 | 차이의 원인 모름 | 10/14 이전 17명 + 10/14 1명 + 10/16 2명 = 20명 | 조회 |
| 직접+그룹 라이선스 중복 | 겹친 동안 상태를 못 봄 | 같은 SKU에 직접·그룹 2건이 모두 Active, 원복 후 그룹 할당만 회수, 사용 20/25 유지 | 조회 |
| 비공개·공유 채널 파일 403 | 원인 모름 | 같은 방식으로 재시도해도 403, 읽기도 403, 새 파일 생성 안 됨. 원인 확인: 관리자 계정은 세 채널 모두 owner 구성원이라 멤버십 문제는 아니고, Cloud Shell 토큰에 Files.*·Sites.* 범위가 없어 채널 전용 사이트 드라이브에 접근하지 못하는 것으로 보임(범위 있는 토큰으로 성공하는 것은 아직 확인하지 못함) ([트러블슈팅 글]({{ "/m365/troubleshooting/channel-upload-403-repro/" | relative_url }})) | 조회 |
| 구독 Owner 서비스 사용자 | 이름 일부만 보임 | 이름 Microsoft-Developer Program-Sample Data Packs, 유형 Application, 생성 2026-08-23, 앱 소유 조직은 외부 | 조회 |
| DG-Practice-01 생성자 | 모름 | 관리자 계정이 2026-10-14 11:14에 생성(감사 로그) | 조회 |
| PIM | 모름 | 활성 4건 모두 영구, 적격 0건 | 조회 |
| 액세스 검토 | 0건 | 0건 재확인 | 조회 |
| Customer Lockbox | Off | Off 재확인(저장 없이 닫음) | 조회 |
| 조건부 액세스 | 0건 | 0건 재확인(GUI) | 조회 |
| 그룹 만료 | 없음 | 없음 재확인 | 조회 |
| Exchange(GUI) | PowerShell이 막혀 못 봄 | 사서함 20(전부 사용자), Microsoft 365 그룹 9 | 조회 |
| Elevate 켬·끔 이력 | 화면 확인만 | Entra 감사 로그와 일치: 10/22 09:57 켬·11:02:59 끔, 10/23 09:46:43 켬·09:50:23 끔, 09:56:36 켬·16:01:10 끔 | 조회 |
| 관리 센터 접속 | M365·Entra·Azure 3곳 | Teams·SharePoint·Exchange·Purview 관리 센터도 열어 값 조회 | 조회 |

![라이선스 사용 수 확인]({{ "/assets/images/2026/10/m11-7-license-check.png" | relative_url }})
*그림 3. Cloud Shell 출력(10/23 저녁 재조회, 위쪽은 실행한 명령). users=20, licensed=20으로 사용자 20명이 모두 라이선스를 갖고 있고, 라이선스 할당 상태는 모두 Active(20건)이며 **전부 직접 할당(direct 20)**이다. 10/23 낮에 동적 그룹으로 겹쳐 들어왔던 그룹 할당은 원복 때 회수되어 지금은 없다. 계정 부분은 가렸다.*

**실행한 스크립트** (준비 코드: [13 글]({{ "/m365/troubleshooting/channel-upload-403-repro/" | relative_url }})의 "공통 준비 코드" 중 토큰·`$h`·`$B` 3줄)

```powershell
$u = (Invoke-RestMethod -Headers $h -Uri "$B/users?`$select=id,assignedLicenses,licenseAssignmentStates&`$top=999").value
"users=$($u.Count) licensed=$(($u | Where-Object { $_.assignedLicenses.Count -gt 0 }).Count)"
$u.licenseAssignmentStates | Group-Object state | ForEach-Object { "state=$($_.Name) count=$($_.Count)" }
$u.licenseAssignmentStates | Group-Object { if ($_.assignedByGroup) {'group'} else {'direct'} } | ForEach-Object { "assigned=$($_.Name) count=$($_.Count)" }
```

![구독 Owner 서비스 사용자 상세]({{ "/assets/images/2026/10/m11-3-service-principal.png" | relative_url }})
*그림 4. 구독 Owner로 등록된 서비스 사용자의 상세(위쪽은 실행한 명령). 이름 Microsoft-Developer Program-Sample Data Packs, 유형 Application, 생성 8/23/2026 7:38:51 PM이 나오고 notes(설명)는 비어 있다. ID 줄과 계정 부분은 가렸다.*

**실행한 스크립트** (Azure 역할 할당은 `Get-AzRoleAssignment`, 서비스 사용자 상세는 Graph로 읽음)

```powershell
$sp = Get-AzRoleAssignment -RoleDefinitionName Owner | Where-Object ObjectType -eq 'ServicePrincipal'
foreach ($a in $sp) {
  Invoke-RestMethod -Headers $h -Uri "$B/servicePrincipals/$($a.ObjectId)?`$select=id,displayName,servicePrincipalType,createdDateTime,notes" |
    Format-List id,displayName,servicePrincipalType,createdDateTime,notes
}
```

![PIM 활성 역할 목록]({{ "/assets/images/2026/10/m11-4-pim-active.png" | relative_url }})
*그림 5. Entra PIM의 활성 역할 목록. Teams 관리자·전역 관리자·청구 관리자 아래 항목이 모두 멤버 자격 "직접", 상태 "할당됨", 종료 시간 "영구"이다. 이름·계정·범위는 가렸다.*

![액세스 검토 목록]({{ "/assets/images/2026/10/m11-5-access-reviews.png" | relative_url }})
*그림 6. Identity Governance > 액세스 검토 화면. 목록에 "표시할 액세스 검토가 없음"으로 나와 0건이다. 계정 표시는 가렸다.*

## 4. 끝내 확인하지 못한 것 (시도 방법 · 사유 · 다음 방법)

| 항목 | 시도 방법 | 막힌 이유 | 다음 방법 |
|---|---|---|---|
| Exchange PowerShell | `Connect-ExchangeOnline` 장치 코드 로그인 | 보안 기본값 때문에 AADSTS530035로 차단. 보안 기본값 변경은 보안 설정 변경이라 하지 않음 | 다른 로그인 방식 검토([05 글]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }})) |
| 청구 계정 유형·청구 역할 | 청구 범위 조회 | 청구 범위가 0건. 역할을 부여받는 것은 보안 변경이라 하지 않음 | 청구 담당자에게 확인 |
| Log Analytics 작업 영역 생성 | (공급자 등록까지만 함) | 작업 영역 생성은 비용 항목이라 하지 않음 | 운영 환경에서 과금 조건을 확인한 뒤 측정 |
| 조건부 액세스 Workbook | (작업 영역이 필요) | Log Analytics 작업 영역이 없음 | 위 작업 영역 생성 후 |
| 끈 뒤 루트 역할 할당 제거 | 끈 뒤 루트 역할 목록 조회 | 목록 자체가 열리지 않음(권한 없음). 대체 근거로 "권한 없음" 안내 복귀 + 감사 로그 사용 | 켠 상태에서만 목록을 볼 수 있어 직접 확인 방법 없음 |
| MFA 실제 로그인 동작 | 로그인 프롬프트 확인 | 본인 계정의 인증 정보를 입력해야 하는 시험이라 하지 않음 | 브라우저 InPrivate 창에서 로그인해 프롬프트 확인 |
| 비상(break-glass) 계정 | 사용자 목록 확인(없음) | 계정 생성은 하지 않음 | 방법 1을 할 때 생성(시험 후 삭제) |
| 구독 Owner 서비스 사용자의 용도 | 서비스 사용자 상세 열기 | 설명 항목이 비어 있음 | 계정 소유자에게 확인 |
| 1:1 채팅 파일·회의 녹화 저장 위치 | OneDrive 열기, Graph `/me/drive` 조회 | (오전) 기본 문서 라이브러리 오류, 조회 HTTP 403. **(오후 재시도) OneDrive가 열리고 Meetings·Recordings 폴더 확인.** 녹화 저장 확인은 마이크·카메라가 필요 | 시험 사용자와 회의를 열어 녹화 |
| 10/22 Planner가 꺼져 있던 원인 | Entra 감사 로그 활동 필터 | (오전) 필터 적용 버튼이 켜지지 않음. **(오후) 드롭다운에서 활동을 골라 적용**하니 7일 범위가 조회됨: 10/22 10:3x 기록 0건, 9:25(5)·9:31·9:34(시스템 그룹 기반 할당) | 원인은 확인 불가 유지(사람이 껐다는 가설만 기각) |
| Purview 감사 상태 | 감사 검색 화면 재방문 | 같은 오류 문구 유지, 검색 버튼 회색(그림은 Purview 글 그림 4) | PowerShell 연결이 가능해진 뒤 `Get-AdminAuditLogConfig` |
| 관리 센터 앱 목록(config.office.com) | 앱 인벤토리 재방문 | "프로비전 중, 최대 24시간" 안내가 표시되어 목록이 비어 있음(그림은 아래) | 24시간 뒤 재조회 |
| 403인데 파일이 생긴 원인 | 10/23에 같은 방식으로 재현 | 새 파일은 생기지 않았고, 10/22 요청·응답을 보존하지 못함 | 다음 재현 시 요청·응답을 저장 |
| 직접+그룹 중복의 운영 기준 | (실험으로 동작은 확인) | 팀 기준이 정해져 있지 않음 | 팀 기준 확인 |

![앱 인벤토리 프로비전 안내]({{ "/assets/images/2026/10/m11-apps-provisioning.png" | relative_url }})
*그림. config.office.com 앱 인벤토리(GUI 경로: config.office.com → 재고)의 프로비전 안내 화면. 10/24 01:15경 다시 열어 선명하게 촬영했고, 이 시점에도 "서비스를 설정하고 있습니다"와 "이 정보 가져오는 중…"이 그대로여서 목록을 읽을 수 없다(월요일 재확인 항목).*

## 5. 정리 후 확인

삭제(팀, 리소스 그룹, 시험 파일 등)는 영구 삭제라 하지 않았습니다. 정리를 마친 뒤 재조회한 결과(Entra 그룹, Teams, 리소스 그룹 수)를 이 글에 한 줄 추가하겠습니다.

**Elevate 재비활성화 확인(10/23 16시경)**: 제가 토글을 다시 끈 뒤 화면으로 확인했습니다(조회). 관리 그룹 화면에서 Tenant Root Group은 "이 관리 그룹을 볼 수 있는 권한이 없습니다" 안내로 돌아왔고, Entra 속성의 "Azure 리소스에 대한 액세스 관리" 토글은 "아니요"이며 저장 버튼은 비활성입니다. 루트 범위 역할 목록을 PowerShell로 직접 다시 읽는 확인은 권한이 없어 하지 못하므로, 위 두 화면과 감사 로그를 근거로 "토글 원복 확인"까지만 적습니다.

> 오늘 입력한 PowerShell 원문은 일부 복구하지 못해, 같은 출력 줄이 나오는 형태로 정리했습니다. 출력 값은 실제와 같습니다.

## 6. 정정 내용 (10/23 검토 반영)

공개한 글을 Microsoft Learn 문서와 다시 대조하다가 고친 부분입니다. 값(조회 결과)은 바꾸지 않았고 해석과 표기를 바로잡았습니다.

| 글 | 고친 내용 |
|---|---|
| 00 사전작업 | vCPU "0/10"은 사용 0, 한도 10이라는 뜻이므로 "여유가 없다"는 해석을 지움(VM을 만들지 않은 이유는 비용 발생 금지 원칙). Cloud Shell의 Graph 모듈은 통합 모듈만 없고 하위 모듈 8개는 기본 설치라고 정정. PIM 근거 문서와 인증 방법 메뉴 경로를 문서 기준으로 정정 |
| 02 D2 Identity 구조 | 그룹 라이선스 할당에 필요한 역할을 Groups / License / User Administrator 중 하나로 정정 |
| 03 D3 Teams 저장 구조 | 공유 채널이 `unknownFutureValue`로 보이는 이유를 evolvable enum과 `Prefer: include-unknown-enum-members` 헤더로 정정 |
| 04 D4 Azure 구조 | 관리 그룹 6단계에 루트·구독 단계가 빠진다는 조건 추가, PowerShell 출력이 재구성한 표기임을 명시, 토글 문서 경로 병기 |
| 05 AADSTS530035 | "보안 기본값이 device-code 흐름을 막는다"는 문장을 문서에서 확인해 확인됨으로 변경 |
| 06 측정 방법 | 판독 분포(합계 82)를 다시 세어 같은 값임을 재확인. 영역별 글의 표와 합산이 맞지 않는 점을 명시하고 원인은 확인 불가로 표기 |
| 07 Identity | 조건부 액세스 403의 원인 후보를 "역할 부족"과 "토큰 범위 부족" 두 가지로 분리 |
| 08 Teams | 공유 채널의 외부 접근은 B2B direct connect(기본 차단)가 필요하다고 정정. 로비 개선안을 옵션 이름으로 명시. 익명 회의 참가 항목을 확인 불가(재측정)로 추가 |
| 09 SharePoint | 퇴사자 OneDrive는 30일 뒤 사이트 모음 휴지통 93일 단계가 있다고 정정. 사용 현황 보고서 지연을 24~72시간으로 정정. SPO 관리 셸 설명 정정. 기본 링크 변경 영향은 문서에서 찾지 못해 확인 불가로 변경 |
| 10 Purview | 클래식 DSPM for AI는 11/30에 종료가 시작되어 12/31까지 완료 예정이라고 정정 |
