---
title: "[M365·Azure] 04 D4 Azure 구조 — 계층, 리소스 그룹, Elevate access 전·후 (전체 기록)"
date: 2026-10-22 10:00:00 +0900
last_modified_at: 2026-10-23 12:00:00 +0900
categories: [m365]
tags: [M365·Azure, D4, Azure, 리소스 그룹, Elevate access, RBAC, 전체 기록]
excerpt: "Azure 계층 구조를 확인하고 비용 없는 리소스 그룹을 만들었고, 전역 관리자의 Elevate access 전·후·원복 상태를 화면과 PowerShell로 비교한 전체 기록"
---

수행일은 2026-10-22(목)이고, 프로그램 일정상 D4(Azure 구조) 주제입니다. Azure 실습이지만 M365·Azure 운영 사전 프로그램의 일부라 M365 분류에 함께 둡니다.

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell에서 직접 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못한 값(시도 방법·사유 병기, 2026-10-23 재확인 반영). 테넌트 ID·구독 ID·도메인·계정은 가렸습니다(그림의 검은 상자). **Elevate access 토글을 켜고 끄는 일은 계정 소유자가 직접 했습니다.**

## 1. 목표

1. Azure의 계층(테넌트 → 관리 그룹 → 구독 → 리소스 그룹 → 리소스)을 화면에서 확인한다.
2. **Azure 역할(RBAC)과 Entra 역할은 서로 다른 체계**임을 확인하고, 둘을 잇는 예외 통로인 **Elevate access**의 전·후를 값으로 비교한다.
3. 비용이 없는 리소스 그룹 2개를 만들어 생성 절차를 연습한다(VM 등 비용 리소스는 만들지 않음).

## 2. 먼저 알아야 할 개념

![관리 그룹, 구독, 리소스 그룹으로 이어지는 Azure 구조와 실습 결과]({{ "/assets/images/2026/10/d4-azure-hierarchy.png" | relative_url }})
*그림 1. Azure 구조와 실습 결과*

| 개념 | 쉬운 설명 |
|---|---|
| 계층 | 테넌트 > (루트) 관리 그룹 > 구독 > 리소스 그룹 > 리소스. 관리 범위(scope)로는 관리 그룹·구독·리소스 그룹·리소스 4단계 |
| RBAC 상속 | 상위 범위에 준 역할은 하위로 상속됨 |
| Entra 역할 ≠ Azure 역할 | 전역 관리자(Entra 역할)라고 해서 Azure 구독·리소스를 자동으로 관리할 수 있는 것은 아님 |
| 루트 관리 그룹 | 기본적으로 **아무도** 접근 권한이 없음. 전역 관리자만 스스로 권한을 올릴 수 있음 |
| Elevate access | 전역 관리자가 자기 자신에게 루트 범위(`/`)의 **User Access Administrator**를 부여하는 기능. 토글로 켜고 끔 |

## 3. 절차

### 3-1. 리소스 그룹 2개 만들기 (09:22)

1. portal.azure.com > 리소스 그룹 > + 만들기
2. 구독 선택, 이름 **rg-practice-d4-01**, 지역 **Korea Central**, 태그 `purpose=readiness-practice` > 검토 + 만들기 > 만들기
3. 같은 방식으로 **rg-practice-d4-02**

![Azure 포털 리소스 그룹 목록. rg-practice-d4-01과 rg-practice-d4-02가 Korea Central에 표시됨]({{ "/assets/images/2026/10/d4-resource-groups.png" | relative_url }})
*그림 2. 리소스 그룹 목록 (빨간 상자: 새로 만든 2개, 계정·구독 정보는 가림)*

### 3-2. Elevate access 전 상태 기록 (09:52)

1. 포털 > 관리 그룹 > **Tenant Root Group** 클릭
2. Entra > 개요 > 속성 > "Azure 리소스에 대한 액세스 관리" 토글 확인(저장 안 함). 영문 문서 표기는 Microsoft Entra ID > Manage > Properties

![Elevate 전. 관리 그룹 화면의 권한 없음 안내와 Entra 속성의 토글 아니요]({{ "/assets/images/2026/10/d4-elevate-before.png" | relative_url }})
*그림 3. Elevate 전 (왼쪽: Tenant Root Group을 눌렀을 때의 안내, 오른쪽: 토글 = 아니요)*

### 3-3. Elevate access 켜기 → 후 상태 기록 (09:57 켬, 계정 소유자 수행)

1. (계정 소유자) Entra > 개요 > 속성 > Azure 리소스에 대한 액세스 관리 > **예** > 저장
2. **로그아웃 후 재로그인** (문서가 요구하는 단계)
3. 포털 > 관리 그룹 > Tenant Root Group > 액세스 제어(IAM) > 역할 할당 탭
4. Cloud Shell에서 같은 값 조회

```powershell
Get-AzRoleAssignment -Scope '/' | Select DisplayName,RoleDefinitionName,Scope,ObjectType
# 출력(재구성): ROOT | User Access Administrator | / | User   ← 첫 열은 계정 이름을 게시하지 않으려고 "ROOT"로 바꿔 적은 표기이며 실제 출력 그대로가 아닙니다
```

![Elevate 후. 루트 IAM 역할 할당 탭에 User Access Administrator가 범위 / 로 보이고, PowerShell도 같은 값]({{ "/assets/images/2026/10/d4-elevate-after.png" | relative_url }})
*그림 4. Elevate 후 (왼쪽: 루트 IAM 역할 할당, 오른쪽: PowerShell 확인, 빨간 상자: 핵심 값)*

### 3-4. Elevate access 끄기 → 원복 후 재확인 (11:02 끔, 11:3x 확인)

1. (계정 소유자) 같은 계정으로 토글을 **아니요**로 바꾸고 저장
2. 관리 그룹 화면과 Entra 속성 토글을 다시 확인

![원복 후. 관리 그룹 화면은 전과 같은 권한 없음 안내로 돌아왔고 토글은 아니요]({{ "/assets/images/2026/10/d4-elevate-reverted.png" | relative_url }})
*그림 5. 원복 후 (왼쪽: 관리 그룹 화면이 "전"과 같아짐, 오른쪽: 토글 = 아니요)*

## 4. 전·후 비교

| 항목 | 전 (09:52) | 후 (09:57 켬 + 재로그인) | 원복 후 (11:02 끔, 11:3x 확인) |
|---|---|---|---|
| Entra 토글 "Azure 리소스에 대한 액세스 관리" | 아니요 | 예 | **아니요** |
| Tenant Root Group 클릭 | "이 관리 그룹을 볼 수 있는 권한이 없습니다" | 접근 가능 | **전과 같은 안내로 복귀** |
| 상단 안내 | "디렉터리 관리자로 등록되었지만 루트 관리 그룹에 액세스하는 데 필요한 권한이 없습니다" | 루트 IAM에 "조치 필요: 이 테넌트에서 1 사용자가 상승된 액세스 권한입니다" 배너 | 전과 같은 안내로 복귀 |
| 루트 IAM 내 할당(활성) | 볼 수 없음 | 활성 1 | - |
| 루트 IAM 역할 할당 탭 | 볼 수 없음 | 관리자 계정에 **User Access Administrator**, 범위 `/`, 상속 | **10/22 재조회 안 함 → 10/23 확인 불가** (끈 뒤에는 이 탭 자체가 열리지 않음) |
| PowerShell `Get-AzRoleAssignment -Scope '/'` | 권한 없음(관리 그룹 설정 조회도 HTTP 403, 10/19) | ROOT 줄: User Access Administrator, 범위 /, 형식 User | **10/22 재조회 안 함 → 10/23 확인 불가** (끈 뒤 조회 권한 없음) |
| 감사 로그(Entra) | - | 09:57 "상승" 기록 | 11:02 "해제" 기록 |

변경 이력(8개 항목):

| 항목 | 내용 |
|---|---|
| 언제 | 켬 09:57 / 끔 11:02 (감사 로그 기준) |
| 무엇을 | 전역 관리자의 Azure 리소스 접근 관리(Elevate access) 토글 |
| 전 → 후 | 아니요 → 예 → 아니요 |
| 누가 | 계정 소유자 본인이 직접 수행. 대행자는 전·후 상태를 조회만 함 |
| 왜 | 루트 관리 그룹 상태와 Azure 역할 체계를 값으로 확인, 보완 항목(관리 그룹 설정) 확인 준비 |
| 근거 | 화면·PowerShell, 감사 로그, 문서 아래 URL |
| 검증 결과 | 루트 IAM에서 User Access Administrator(`/`) 확인, 원복 후 화면과 토글이 전 상태와 같음 |
| 원복 방법 | 같은 토글을 아니요로 저장(실행 완료). 루트 범위 역할 목록 재조회는 **남은 확인 항목** |

## 5. 리소스 그룹 전·후

| 항목 | 만들기 전 | 만든 후 |
|---|---|---|
| 리소스 그룹 수 | 1 (기존 1개는 Southeast Asia) | **3** |
| 새 그룹 | - | rg-practice-d4-01, -02 / Korea Central / 태그 purpose=readiness-practice / 상태 Succeeded |
| 리소스 | - | 없음 (VM 등은 만들지 않음, 비용 없음) |
| 구독 역할 | Owner 2건(사용자 1 + 서비스 사용자 1), 모두 영구 활성, 적격(PIM) 0 | 변화 없음 |

## 6. 문제점과 원인, 해결 방안

### 문제 1 — 전역 관리자인데 루트 관리 그룹을 볼 수 없다
- **원인(문서·조회)**: Entra의 전역 관리자 역할과 Azure RBAC는 별개입니다. 루트 관리 그룹은 기본적으로 아무에게도 접근 권한이 없고, 전역 관리자만 스스로 권한을 올릴 수 있습니다. 관리 그룹 설정 조회가 403(`settings/read` 권한 없음)이었던 것도 같은 이유입니다.
- **해결 방안**: Elevate access를 켜서 **필요한 만큼만, 필요한 시간 동안** 루트 범위 User Access Administrator를 받고, 확인이 끝나면 즉시 끕니다.

### 문제 2 — 켠 직후에는 화면이 그대로다
- **원인(문서)**: 권한 상승 후 **로그아웃 후 다시 로그인**해야 토큰에 반영됩니다. 이번에도 재로그인 후에야 후 상태를 확인했습니다.
- **해결 방안**: 절차에 "재로그인"을 명시합니다.

### 문제 3 — 켜면 어떤 권한이 생기는가
- **조회**: 생긴 것은 **User Access Administrator**(루트 범위 `/`)이며, Owner나 Contributor가 아닙니다. 이 역할은 다른 사용자에게 Azure 역할을 줄 수 있는 역할이라, 켜 둔 시간 동안은 **그 계정이 루트 범위에서 권한을 부여할 수 있는 상태**입니다.
- **해결 방안**: 사용 후 즉시 끄고, 끈 뒤에도 루트 IAM의 할당이 사라졌는지 확인합니다(문서는 토글을 끄면 제거된다고 설명).

### 문제 4 — 루트 IAM에 경고 표시
- **관찰**: 후 상태 IAM 화면에 `denyAssignments/read` 관련 경고가 떴습니다.
- **원인**: **확인 불가**. 부여된 역할에 그 읽기 권한이 포함되지 않기 때문일 수 있다는 추정만 있습니다(사유: 역할 정의를 바꾸거나 다른 역할을 받아 확인하는 것은 권한 변경이라 하지 않음).

### 문제 5 — 원복 후 루트 역할 목록을 다시 읽지 않았다
- 11:3x 시점에 토글 "아니요"와 관리 그룹 화면의 "전과 같은 안내"는 확인했지만, **루트 범위 역할 목록을 PowerShell로 다시 조회하지는 않았습니다.** 그래서 10/22 시점에는 "할당이 사라졌다"는 결론을 **확인 불가**로 남겼습니다. 10/23에 이 확인을 다시 시도한 결과는 아래 "10/23 재확인"에 적었습니다. 직접 목록으로는 끝내 확인하지 못하므로 "원복 완료"가 아니라 "토글 원복 확인 + 감사 로그 대조"라고 씁니다.

### 문제 6 — Elevate에 사전 승인이 필요한가
- 가이드·문서만으로는 조직 내부의 사전 승인 절차를 알 수 없습니다. **확인 불가**입니다(시도: 가이드·문서 검색, 사유: 조직 내부 규정이라 문서에 없음). 팀장 질문으로 남겼습니다.

## 7. 역할 할당 실습(범위별 상속 확인)은 하지 않았다

- 범위별 역할 할당(관리 그룹/구독/리소스 그룹)은 계정 소유자가 직접 수행하기로 한 작업입니다. 따라서 이 글에는 **"하위 범위에서 상속됨" 표시를 확인한 값이 없고, 해당 항목은 10/22 시점에 확인 불가**였습니다(문서상 RBAC는 상위에서 하위로 상속). 10/23에 기존 할당을 조회해 일부 확인한 값은 아래 "10/23 재확인"에 적었습니다.

## 8. 검증

| 검증 | 결과 |
|---|---|
| 리소스 그룹 수 1→3, 새 그룹 Succeeded | 확인 |
| Elevate 전: 권한 없음 안내 + 토글 아니요 | 확인 |
| Elevate 후: 루트 IAM에 UAA(`/`), PowerShell ROOT 줄: User Access Administrator, 범위 /, 형식 User | 확인 |
| 감사 로그: 09:57 상승 / 11:02 해제 | 확인 |
| 원복 후: 토글 아니요, 관리 그룹 화면이 전과 같음 | 확인 |
| 원복 후 루트 역할 목록(PowerShell) | **확인 불가** (10/23에도 끈 뒤에는 목록이 열리지 않아 대체 근거로 "권한 없음" 안내 복귀 + 감사 로그를 사용) |

## 9. 운영에서는 이렇게 판단한다

- Azure 역할과 Entra 역할을 **한 표에 같이 놓고** 담당자를 정해 둡니다. "전역 관리자니까 구독도 다 본다"는 가정은 틀립니다.
- 구독 Owner가 영구 활성 2명이고 적격 할당이 0입니다. 문서는 구독 Owner를 최대 3명으로 제한하라고 권하고, Microsoft Entra ID P2가 있으면 PIM으로 시간제 활성화(적격)를 쓸 수 있습니다. 이 테넌트는 P2가 있으나 적격 할당은 0입니다.
- Elevate access는 "쓰고 나면 끄는" 기능입니다. **켠 시각과 끈 시각을 기록**하고, 끈 뒤에도 루트 범위 할당을 한 번 더 읽어 둡니다.
- 비용이 나올 수 있는 구독(지출 한도 Off)에서는 연습을 **리소스 그룹처럼 비용 없는 객체**로만 합니다.

## 10. 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 문서 | Elevate access: 루트 `/`에서 User Access Administrator, 로그아웃·재로그인, 토글 끄기로 제거, 배너 | [Elevate access](https://learn.microsoft.com/azure/role-based-access-control/elevate-access-global-admin) |
| 문서 | 관리 그룹: 루트 "Tenant root group", 기본 접근 없음, 전역 관리자만 상승, 계층 6단계(루트와 구독 단계는 제외), RBAC 상속 | [Management groups](https://learn.microsoft.com/azure/governance/management-groups/overview) |
| 문서 | 관리 범위 4단계와 상속 | [Resource Manager 개요](https://learn.microsoft.com/azure/azure-resource-manager/management/overview) |
| 문서 | Azure 역할 vs Entra 역할 | [RBAC와 디렉터리 관리자 역할](https://learn.microsoft.com/azure/role-based-access-control/rbac-and-directory-admin-roles), [Entra 역할 개념](https://learn.microsoft.com/entra/identity/role-based-access-control/concept-understand-roles) |
| 문서 | 구독은 하나의 테넌트를 신뢰, Azure 역할 ≠ Entra 역할 | [구독과 디렉터리](https://learn.microsoft.com/entra/fundamentals/how-subscriptions-associated-directory) |
| 문서 | 리소스 관리 보안 | [Secure resource management](https://learn.microsoft.com/entra/architecture/secure-resource-management) |
| 문서 | 리소스 그룹 만들기 | [Manage resource groups (portal)](https://learn.microsoft.com/azure/azure-resource-manager/management/manage-resource-groups-portal) |
| 문서 | 구독 Owner 최대 3명 권장 등 | [Best practices for Azure RBAC](https://learn.microsoft.com/azure/role-based-access-control/best-practices) |
| 문서 | 적격·시간제 역할 할당(PIM 연동) | [Eligible and time-bound assignments](https://learn.microsoft.com/azure/role-based-access-control/pim-integration) |
| 조회 | 리소스 그룹 1→3, Elevate 전·후·원복 화면, PowerShell ROOT 행, 감사 로그 09:57/11:02 | Azure 포털·Entra·Cloud Shell |
| 확인 불가 | 원복 후 루트 역할 목록(끈 뒤 조회 불가) / denyAssignments 경고 원인(추정만 가능) / Elevate 사전 승인 필요 여부(규정이 문서에 없음) / 사용자 직접 할당의 상속 결과(할당을 하지 않음) | - |

## 11. 정리·남은 일

- 리소스 그룹 2개는 **삭제하지 않았고** 정리 목록에 올렸습니다(본인 수행 예정).
- 범위별 역할 할당과 되돌리기는 본인 작업으로 남아 있습니다.
- 원복 후 루트 범위 역할 목록 재조회는 끈 뒤 목록이 열리지 않아 직접 확인할 수 없습니다. 대신 아래 10/23 근거로 대신합니다.

## 12. 10/23 재확인

- **감사 로그(Entra, Azure RBAC Elevated Access)**: 10/22 09:57 켬 → 11:02:59 끔, 10/23 09:46:43 켬 → 09:50:23 끔. 켜고 끈 시각이 모두 기록됐습니다(조회).
- **끈 뒤 화면**: 관리 그룹 화면이 다시 "권한 없음" 안내로 돌아왔습니다(조회). 루트 역할 목록 자체는 열리지 않아 "제거됨"은 이 화면으로 직접 보지 못했습니다.
- **켠 상태**: 루트 역할 목록에 User Access Administrator 1건(PowerShell도 1건)을 다시 확인했습니다(조회).
- **관리 그룹 설정**: 켠 상태에서 포털 토큰을 갱신하자 읽혔습니다([트러블슈팅 글]({{ "/m365/troubleshooting/mg-settings-403-elevate-refresh/" | relative_url }})).
- **상속**: 리소스 그룹 범위의 기존 할당을 조회했더니 구독 Owner가 구독 범위에서 상속되어 표시됐고 User Access Administrator는 루트(`/`) 범위였습니다(조회). 사용자에게 새로 할당한 역할(Reader 등)의 상속은 할당을 하지 않아 확인 불가입니다.

> 오늘 입력한 PowerShell 원문은 복구하지 못해, 같은 출력 줄이 나오는 형태로 정리했습니다. 화면 확인 값은 실제와 같습니다.
