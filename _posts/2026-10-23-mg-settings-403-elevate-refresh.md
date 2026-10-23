---
title: "[M365·Azure] 12 트러블슈팅 — 관리 그룹 설정이 403일 때, Elevate access 뒤 토큰 갱신으로 읽기 (전체 기록)"
date: 2026-10-23 10:10:00 +0900
categories: [m365, troubleshooting]
tags: [Azure, 관리 그룹, Elevate access, 토큰, 403, 전체 기록]
excerpt: "10/19에 HTTP 403으로 못 읽은 관리 그룹 설정을 Elevate access를 켠 뒤 포털 토큰을 갱신해 읽은 과정과, 끈 뒤 화면 복귀까지의 기록"
---

> 근거 표기: **조회** = 이 테넌트 화면·PowerShell에서 직접 읽은 값 / **문서** = Microsoft Learn / **확인 불가** = 시도했으나 확인하지 못함(시도 방법·사유 병기). 테넌트 ID·구독 ID·도메인·계정은 게시하지 않았고, **Elevate access 토글을 켜고 끄는 일은 계정 소유자가 직접 했습니다.**

## 1. 증상

- 10/19: 관리 그룹의 계층 보호 설정을 REST로 읽으면 HTTP 403(settings/read 권한 없음). 현재 값을 알 수 없었습니다.
- 10/22: Elevate access를 켜서 루트 범위 권한은 확인했지만([D4 글]({{ "/m365/readiness-d4-azure-structure/" | relative_url }})), 관리 그룹 설정 값은 기록하지 못했습니다.

## 2. 원인 추적

1. **권한이 없는 상태에서의 403**: 전역 관리자라도 Azure 루트 관리 그룹의 권한은 자동으로 없습니다. 관리 그룹 화면에서 "권한 없음" 안내가 나오는 이유와 같습니다(10/22 D4 글).
2. **Elevate를 켰는데도 안 읽힘(10/23)**: 09:46:43에 켠 직후 관리 그룹 설정을 열었지만 값이 읽히지 않았습니다.
3. **토큰 문제로 좁힘**: 문서는 권한을 올린 뒤 "로그아웃 후 다시 로그인해 액세스를 갱신"하라고 안내하고(문서: Elevate access 문서 Step 1-5), 관리 그룹 캐시와 토큰은 최대 30분 동안 유지되며 브라우저 새로 고침·재로그인·새 토큰 요청으로 갱신할 수 있다고 설명합니다(문서: 관리 그룹 관리 문서). 그래서 **권한을 올린 뒤에도 이전 토큰이 남아 있어서 읽지 못하는 것**으로 추정했습니다. (이 추정은 토큰 내용을 직접 디코딩해 확인한 것이 아니라 결과로 맞춘 것입니다.)

## 3. 해결

포털 주소 끝에 `?feature.refreshtoken=true`를 붙여 포털을 다시 불러 토큰을 새로 받았습니다. 다시 열자 값이 읽혔습니다.

| 항목 | 10/19 | 10/23 (Elevate 켠 상태, 토큰 갱신 후) |
|---|---|---|
| 기본 관리 그룹 | 읽지 못함(403) | Tenant Root Group |
| 계층 보호 | 읽지 못함(403) | Off |

## 4. 끈 뒤

Elevate를 09:50:23에 껐고, 관리 그룹 화면은 다시 "권한 없음" 안내로 돌아왔습니다(조회). Entra 감사 로그(Azure RBAC Elevated Access)에 켬 09:46:43, 끔 09:50:23이 기록돼 있습니다(조회). 끈 뒤에는 루트 역할 목록 자체가 열리지 않아 "할당이 제거됐다"는 것을 목록으로는 직접 보지 못합니다 → **확인 불가**(시도: 끈 뒤 루트 IAM 열기, 사유: 권한 없음). 대체 근거는 "권한 없음" 안내 복귀와 감사 로그입니다.

## 5. 운영에서는 이렇게 판단한다

- Elevate를 켠 직후에 값이 안 읽히면 권한 부족으로 단정하기 전에 **토큰 갱신**(재로그인 또는 새로 고침)을 먼저 시도합니다.
- 켠 시간은 짧게 쓰고, 쓰고 나면 곧바로 끕니다. 켬·끔은 감사 로그에 남으므로 시각을 변경 이력에 같이 적습니다.
- PIM을 쓰는 경우 역할 비활성화만으로는 토글이 "아니요"로 돌아가지 않습니다. 토글을 먼저 끄고 비활성화합니다(문서).

## 6. 근거 자료

| 구분 | 내용 | 출처 |
|---|---|---|
| 문서 | Elevate access 절차, 끄는 방법, PIM 주의 | [Elevate access to manage all Azure subscriptions and management groups](https://learn.microsoft.com/azure/role-based-access-control/elevate-access-global-admin) |
| 문서 | 토큰·캐시 30분, 갱신 방법 | [Manage your Azure subscriptions at scale with management groups](https://learn.microsoft.com/azure/governance/management-groups/manage) |
| 조회 | 기본 관리 그룹·계층 보호 값, 끈 뒤 화면, 감사 로그 시각 | Azure 포털·Entra |
