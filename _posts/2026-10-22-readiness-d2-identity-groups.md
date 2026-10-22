---
title: "[M365 Readiness] D2 Identity 구조 — 동적 그룹과 그룹 라이선스 (전체 기록)"
date: 2026-10-22 09:20:00 +0900
categories: [m365]
tags: [Readiness, D2, Entra, 동적 그룹, 그룹 라이선스, 전체 기록]
excerpt: "동적 그룹 생성, 그룹에 E5 라이선스 할당, 부서 값 변경으로 자동 가입, 원복까지의 전·후 값과 막힌 곳, 근거 자료를 모두 남긴 기록"
---

수행일은 2026-10-22(목)이고, 프로그램 일정상 D2(Identity 구조) 주제입니다. 사용자 유형·그룹·인증 방식은 10/19에 읽기만 해 두었고, 10/22에 변경 실습을 했습니다.

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell에서 직접 읽은 값 / **문서** = Microsoft Learn / **미확인** = 확인하지 못한 값. 테넌트 ID·도메인·계정·사용자 이름은 게시하지 않았고, 시험 사용자는 "시험 사용자 2"처럼 적었습니다.

## 1. 목표

1. Member/Guest, 그룹 유형, 인증 방식(PHS·PTA·Federation)을 정리한다.
2. **동적 그룹**이 사용자 속성(부서) 변경에 반응해 자동으로 구성원을 넣고 빼는지 직접 확인한다.
3. **그룹 기반 라이선스**를 할당하고, 그룹에서 빠졌을 때 라이선스가 어떻게 되는지 확인한다.

## 2. 먼저 알아야 할 개념

![부서 값 변경, 규칙 평가, 그룹 자동 가입, 라이선스 반영 순서]({{ "/assets/images/2026/10/d2-dynamic-group.png" | relative_url }})
*그림 1. 동적 그룹 동작 순서*

| 개념 | 쉬운 설명 |
|---|---|
| 보안 그룹 / Microsoft 365 그룹 | 보안 그룹은 권한·라이선스 대상 지정용, M365 그룹은 Teams·메일 같은 협업용 |
| 동적 그룹 | 규칙(예: 부서가 Sales)을 정해 두면 조건에 맞는 사용자가 자동으로 들어오고 나가는 그룹. Entra ID P1 이상 필요 |
| 그룹 기반 라이선스 | 사용자 하나씩이 아니라 그룹에 라이선스를 주면 구성원에게 자동 반영 |
| Source of authority(원본) | 그 개체의 "원본"이 어디인지. 동기화된 속성은 온-프레미스 AD에서만 고치고, 클라우드 전용은 Entra에서 직접 고침 |
| PHS / PTA / Federation | 온-프레미스 AD 암호로 클라우드에 로그인하는 3가지 방식. PHS=암호 해시 동기화, PTA=로그인 때마다 온-프레미스 에이전트 확인, Federation=AD FS 같은 외부 서버에 위임 |

## 3. 10/19 사전 조회 (변경 없음)

| 확인 대상 | GUI 경로 | 조회한 값 |
|---|---|---|
| 그룹 목록 | Entra ID > 그룹 > 모든 그룹 | 9개: Microsoft 365 8 + 보안 1(DG-Practice-01) |
| 새 그룹 폼 | 새 그룹 > 멤버십 유형 | 할당됨 / 동적 사용자 / 동적 디바이스 3종. 동적 사용자를 고르면 "동적 쿼리 추가"가 나타남(저장하지 않고 닫음) |
| 규칙 작성기 | 동적 쿼리 추가 | 규칙 구성·규칙 유효성 검사 탭, 속성(accountEnabled, department, jobTitle, mail … 스크롤하면 더 있음), MemberOf는 미리 보기 |
| 기존 동적 그룹 | DG-Practice-01 > 개요·동적 구성원 규칙·라이선스 | 규칙 `user.department -eq "Sales"`, 구성원 18, 처리 상태 성공, 생성 2026-10-14, 라이선스 할당 없음 |
| 사용자 | Entra ID > 사용자 > 모든 사용자 | 20명 전원 Member, Guest 0, 온-프레미스 동기화 "아니요" |
| 원본 | 사용자 속성 | 부서·직위가 클라우드에서 수정 가능(속성 편집 아이콘 있음) |
| 동기화 | Entra Connect > 시작 | 메뉴 3개(시작/클라우드 동기화/동기화 연결), 동기화 구성 정보 없음 |
| 도메인 | Entra ID > 도메인 이름 | 1개, 사용 가능, 인증 Managed, 페더레이션 열 비어 있음 |
| 라이선스 현황 | M365 관리 센터 > 청구 > 라이선스 | 20/25. 사용자 20명이 모두 **개별(직접) 할당** |

PowerShell 확인(읽기):

```powershell
$B = 'https://graph.microsoft.com/v1.0'
$gid = (((Invoke-AzRestMethod -Uri "$B/groups?`$filter=displayName eq 'DG-Practice-01'&`$select=id").Content | ConvertFrom-Json).value[0].id)
(((Invoke-AzRestMethod -Uri "$B/groups/$gid/members?`$select=displayName,department").Content | ConvertFrom-Json).value).Count   # 18
```

- **의미**: 이 테넌트는 클라우드 전용이라 PHS·PTA·Federation과 Connect Sync/Cloud Sync는 **실습할 수 없고 문서로만 정리**했습니다(동기화 메뉴에 구성 정보 없음 = 조회).
- **미확인**: DG-Practice-01은 소유자가 0이고 누가 만들었는지 확인하지 못했습니다. 그래서 건드리지 않았습니다.

## 4. 10/22 변경 실습

### 4-1. 동적 그룹 DG-Practice-02 만들기 (09:26)

**GUI 경로**: entra.microsoft.com > 그룹 > 모든 그룹 > 새 그룹 > 그룹 유형 보안 / 이름 DG-Practice-02 / 멤버십 유형 "동적 사용자" > 동적 쿼리 추가 > 속성 department / 연산자 Equals / 값 Practice02 > 저장 > 만들기

![그룹 목록. 빨간 상자가 새로 만든 동적 그룹 행]({{ "/assets/images/2026/10/d2-groups-list.png" | relative_url }})
*그림 2. 그룹 목록 (계정·개체 ID는 가림, 빨간 상자: DG-Practice-02)*

![그룹 개요 화면. 멤버십 유형 동적, 규칙 처리 상태, 구성원 수가 보임]({{ "/assets/images/2026/10/d2-group-overview.png" | relative_url }})
*그림 3. 그룹 개요 (빨간 상자: 멤버십 유형과 구성원 수)*

![동적 구성원 규칙 화면. 속성 department, 연산자 Equals, 값 Practice02]({{ "/assets/images/2026/10/d2-dynamic-rule.png" | relative_url }})
*그림 4. 동적 규칙 화면 (빨간 상자: 규칙 구문)*

| 항목 | 만들기 전 | 만든 직후 |
|---|---|---|
| 그룹 수 | 9 | 10 |
| DG-Practice-02 | 없음 | 보안 / 동적 사용자 / 규칙 `(user.department -eq "Practice02")` |
| 구성원 | - | 0 |

### 4-2. 그룹에 E5 라이선스 할당 (09:27)

**GUI 경로**: Entra의 그룹 > 라이선스 탭을 열면 "라이선스 할당 추가, 제거 또는 재처리는 M365 관리 센터 내에서만 사용할 수 있습니다" 안내가 나옵니다. 그래서 **M365 관리 센터 > 청구 > 라이선스 > Microsoft 365 E5 Developer SKU V2(할당 전 20/25) > 라이선스 할당 > 그룹 DG-Practice-02 선택 > 할당**으로 했습니다. "라이선스가 할당되고 있습니다" 메시지가 나왔습니다.

![Entra 그룹 라이선스 탭. 관리 센터에서만 할당할 수 있다는 안내]({{ "/assets/images/2026/10/d2-group-license.png" | relative_url }})
*그림 5. Entra 그룹의 라이선스 탭 (빨간 상자: 관리 센터 이동 안내와 할당된 제품)*

확인(읽기):

```powershell
$B = 'https://graph.microsoft.com/v1.0'
$grp = ((Invoke-AzRestMethod -Uri "$B/groups?`$filter=displayName eq 'DG-Practice-02'&`$select=id,membershipRuleProcessingState,assignedLicenses").Content | ConvertFrom-Json).value[0]
"GRP|state=$($grp.membershipRuleProcessingState)|lic=$($grp.assignedLicenses.Count)"    # GRP|state=On|lic=1
```

### 4-3. 부서 값을 바꿔 자동 가입 확인 (09:29) → 원복 (09:33)

대상은 **시험 사용자 2**입니다. 이 사용자는 이미 직접 라이선스를 갖고 있습니다.

1. Entra > 사용자 > 시험 사용자 2 > 개요: 부서 비어 있음, 그룹 구성원 자격 **2**, 라이선스 1
2. 속성 편집 > 작업 정보 > 부서에 `Practice02` 입력 > 저장
3. DG-Practice-02 > 구성원 확인 + PowerShell 조회
4. 부서를 **빈 값으로 되돌려 저장** (09:33) 후 다시 조회

![원복 후 사용자 라이선스 화면. E5 제품 하나, 상태 Active]({{ "/assets/images/2026/10/d2-user-license-after.png" | relative_url }})
*그림 6. 원복 후 시험 사용자 2의 라이선스 화면 (빨간 상자: 제품과 상태, 이름·계정은 가림)*

```powershell
$mem = ((Invoke-AzRestMethod -Uri "$B/groups/$($grp.id)/members?`$select=displayName,department").Content | ConvertFrom-Json).value
"MEMBERS|$($mem.Count)"
# 사용자 쪽: licenseAssignmentStates(byGroup 여부, state)와 subscribedSkus(사용 수)도 같이 조회
```

## 5. 전·후 비교

| 항목 | 변경 전 | 부서=Practice02 저장 후 | 원복 후(부서 비움) |
|---|---|---|---|
| 시험 사용자 2 부서 | 비어 있음 | Practice02 | 비어 있음 (`dept=[]`) |
| DG-Practice-02 구성원 수 | 0 | **1** (해당 사용자, 부서 Practice02) | **0** |
| 시험 사용자 2의 그룹 구성원 자격 | 2 | 변경 후 값은 따로 기록하지 못함 | - |
| 그룹의 라이선스 | 할당 1건 | 할당 1건 | 할당 1건 |
| 사용자의 라이선스 소스 | 직접 | 그룹 경로가 추가되었는지 여부와 상세 값은 따로 기록하지 못함 | **직접만 유지**, `byGroup` 비어 있음, 상태 Active |
| SKU 사용 수 | 20 / 25 | 겹친 동안의 값은 기록하지 못함 | **20 / 25** |
| 그룹 수 | 10 | 10 | 10 → (Team 생성으로 11, D3 참고) |

변경 이력(8개 항목):

| 항목 | 내용 |
|---|---|
| 언제 | 2026-10-22 09:26 ~ 09:33 |
| 무엇을 | ① 동적 그룹 DG-Practice-02 생성 ② 그룹에 E5 라이선스 할당 ③ 시험 사용자 2의 부서 비움→Practice02→비움 |
| 전 → 후 | 그룹 9→10, 그룹 라이선스 0→1, 사용자 부서 변경 후 원복(최종: 구성원 0, 부서 비어 있음) |
| 누가 | 대행(승인: 본인) |
| 왜 | 동적 규칙 반응과 그룹 라이선스 흐름을 값으로 확인 |
| 근거 | 화면 + Graph 조회, 문서 아래 URL |
| 검증 결과 | `MEMBERS` 0→1→0, `dept=[]`, SKU 20/25 |
| 원복 방법 | 사용자 부서 원복(완료). 그룹은 **그룹 라이선스를 먼저 제거한 뒤 그룹 삭제**(정리 목록, 본인 수행 예정) |

## 6. 문제점과 원인, 해결 방안

### 문제 1 — 그룹 라이선스를 Entra에서 할당할 수 없다
- **원인**: Entra의 그룹 > 라이선스 탭에는 할당 버튼이 없고 "M365 관리 센터에서만 가능"하다는 안내뿐입니다(조회). 문서에도 관리 센터에서 그룹 라이선스를 관리한다고 되어 있습니다.
- **해결 방안**: 관리 센터의 라이선스 할당 패널에서 대상 유형을 그룹으로 고릅니다. 문서에 따르면 최소 License Administrator 이상이 필요하고, 중첩 그룹은 지원되지 않으며, 오류는 "오류 및 문제" 탭과 재처리로 처리합니다.

### 문제 2 — 직접 라이선스와 그룹 라이선스가 겹친다
- **상황**: 시험 사용자 2는 이미 직접 E5를 갖고 있는데 그룹에도 같은 E5를 줬으므로, 그룹에 들어가면 같은 제품이 두 경로로 걸릴 수 있습니다.
- **관찰(조회)**: 부서를 되돌려 그룹에서 빠지자 그룹 쪽 할당이 사라지고 **직접 할당만 남았으며** 사용 수는 20/25로 돌아왔습니다.
- **미확인**: 겹쳐 있는 동안 SKU 사용 수가 어땠는지, 그리고 "직접+그룹 중복일 때 운영 기준으로 어느 쪽을 정리하는 것이 맞는가"는 확인하지 못했습니다. 질문으로 남겼습니다.
- **해결 방안(원칙)**: 그룹 라이선스로 옮길 때는 먼저 그룹에 할당하고, 반영을 확인한 뒤에 직접 할당을 제거하는 순서가 안전합니다. 문서에도 사용자를 그룹 사이에서 옮길 때 "먼저 추가, 나중에 제거" 순서를 권합니다.

### 문제 3 — 규칙이 "얼마 만에" 반응하는지 모른다
- **관찰**: 부서를 저장한 뒤 조회했을 때 구성원 1이 보였습니다. 하지만 **반응 시간을 재지는 않았습니다(미확인)**. 문서는 속성이 바뀌면 규칙이 다시 평가된다고만 설명합니다.
- **해결 방안**: 운영에서는 "즉시"라고 가정하지 않고, 변경 후 일정 시간 뒤 확인하는 절차로 씁니다.

### 문제 4 — 원본이 클라우드가 아니면 이 방법이 안 된다
- 이 테넌트는 사용자·그룹의 원본이 모두 클라우드라서 Entra에서 부서를 직접 고칠 수 있었습니다. **온-프레미스 AD에서 동기화된 사용자라면 부서를 AD에서 고쳐야** 하고, Entra에서 편집하는 방식은 통하지 않습니다.

### 문제 5 — 이전 기록의 부정확한 값 정정
- 이전 정리본에 "그룹 구성원 자격 2→3", "탈퇴 결과 미확인"이라고 적었던 부분은 이렇게 바로잡습니다: 변경 전 사용자의 그룹 구성원 자격은 2, 변경 후 **그룹의 구성원 수가 1**, 원복 후 **0**. 탈퇴는 확인되었습니다.

## 7. 검증

| 검증 | 결과 |
|---|---|
| 그룹 목록 9→10 | 확인 |
| 개요: 멤버십 유형 동적, 구성원 0 | 확인 |
| 라이선스 할당 메시지, 그룹 `lic=1` | 확인 |
| 부서 변경 후 `MEMBERS`=1 | 확인 |
| 원복 후 `MEMBERS`=0, `dept=[]` | 확인 |
| 원복 후 `byGroup` 비어 있음, 직접 유지, SKU 20/25 | 확인 |
| 조건부 액세스 정책 조회 | HTTP 403(D5 참고, 이 글의 범위 아님) |

## 8. 운영에서는 이렇게 판단한다

- 부서·직책처럼 **속성이 정확히 관리되는 조직**에서만 동적 그룹이 안전합니다. 속성 입력이 사람마다 다르면 규칙에서 빠지거나 의도치 않게 들어옵니다.
- 라이선스를 그룹 단위로 주면 입사·이동·퇴사 때 수작업이 줄지만, **그룹 규칙이 곧 라이선스 정책**이 되므로 규칙 변경도 변경 관리 대상입니다.
- 소유자 없는 그룹(DG-Practice-01)은 누가 책임지는지 모르는 상태이므로 운영 점검 항목에 넣습니다.

## 9. 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 문서 | 그룹 기반 라이선스를 관리 센터에서 관리, 필요 역할, 중첩 불가, 오류·재처리 | [Manage group licenses](https://learn.microsoft.com/microsoft-365/admin/manage/manage-group-licenses) |
| 문서 | 동적 그룹 규칙, P1 필요, 속성 변경 시 재평가 | [Dynamic membership rules](https://learn.microsoft.com/entra/identity/users/groups-dynamic-membership), [규칙 만들기](https://learn.microsoft.com/entra/identity/users/groups-create-rule) |
| 문서 | 그룹 유형 비교 | [Compare groups](https://learn.microsoft.com/microsoft-365/admin/create-groups/compare-groups) |
| 문서 | 그룹 라이선스를 관리 센터에서 관리한다는 설명과 PowerShell 예 | [Licensing PowerShell/Graph examples](https://learn.microsoft.com/entra/identity/users/licensing-powershell-graph-examples) |
| 문서 | 하이브리드 일치 방식(hard match=sourceAnchor, soft match=UPN/SMTP, 관리자 역할 계정은 일치 대상 아님) | [기존 테넌트에 Connect 설치](https://learn.microsoft.com/entra/identity/hybrid/connect/how-to-connect-install-existing-tenant), [동기화 오류](https://learn.microsoft.com/entra/identity/hybrid/connect/tshoot-connect-sync-errors) |
| 문서 | PHS·PTA·Federation 비교 | [인증 방식 선택](https://learn.microsoft.com/entra/identity/hybrid/connect/choose-ad-authn) (이번 글에서 URL 재검증은 안 함) |
| 조회 | 그룹 9→10, 규칙, 구성원 0→1→0, 라이선스 `lic=1`, SKU 20/25 | Entra·관리 센터 화면 + Graph |
| 미확인 | 규칙 반응 시간, 겹친 동안 사용 수, 직접+그룹 중복의 운영 기준, DG-Practice-01 소유자 | - |

## 10. 정리·남은 일

- **원복 완료**: 시험 사용자 2의 부서(비움).
- **본인 작업으로 남음**: DG-Practice-02 정리 — 먼저 그룹에 할당된 라이선스를 제거한 뒤 그룹을 삭제합니다(삭제는 이번 실습에서 하지 않음).

> 오늘 입력한 PowerShell 원문은 복구하지 못해, 같은 출력 줄이 나오는 형태로 정리했습니다. 화면 확인 값은 실제와 같습니다.
