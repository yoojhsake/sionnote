---
title: "[M365 Readiness] D4 Azure 구조 — 관리 그룹·구독·리소스 그룹"
date: 2026-10-22 10:00:00 +0900
categories: [m365]
tags: [Readiness, D4, Azure, 리소스 그룹, Elevate access]
excerpt: "Azure의 계층 구조를 확인하고 비용이 없는 리소스 그룹 두 개로 생성을 연습한 기록"
---

수행일은 2026-10-22이고, 프로그램 일정상 D4(Azure 구조) 주제입니다. Azure 실습이지만 Readiness 프로그램의 일부라 M365 분류에 함께 둡니다.

## 목표
관리 그룹 → 구독 → 리소스 그룹의 계층을 화면에서 확인하고, 비용이 들지 않는 리소스 그룹을 만들어 본다.

## 절차
1. Azure 포털 > 관리 그룹에서 Tenant Root Group과 구독의 위치를 확인한다.
2. 리소스 그룹 **rg-practice-d4-01, rg-practice-d4-02**를 Korea Central에 만든다(태그 purpose=readiness-practice).
3. 생성 결과(Succeeded)와 전·후 목록을 확인한다.
4. 역할 할당은 **하지 않는다**.

![관리 그룹, 구독, 리소스 그룹으로 이어지는 Azure 구조와 실습 결과]({{ "/assets/images/2026/10/d4-azure-hierarchy.png" | relative_url }})
*그림 1. Azure 구조와 실습 결과*

## 실제 값
![Azure 포털 리소스 그룹 목록. rg-practice-d4-01과 rg-practice-d4-02가 Korea Central에 표시됨]({{ "/assets/images/2026/10/d4-resource-groups.png" | relative_url }})
*그림 2. 리소스 그룹 목록 (빨간 상자: 새로 만든 2개, 계정·구독 정보는 가림)*

| 항목 | 값 |
|---|---|
| 리소스 그룹 수 | 1개 → 3개 |
| 새 리소스 그룹 | rg-practice-d4-01, -02 (Korea Central, 리소스 없음, 비용 없음) |
| 생성 상태 | ProvisioningState Succeeded |
| 구독 역할 할당 | 소유자 2건 모두 영구 활성, 적격(PIM) 0 |

## 막힌 곳과 원인
- 관리 그룹 화면에서 처음에 "이 관리 그룹을 볼 수 있는 권한이 없습니다"라는 안내가 떴다.
- 루트 범위를 보려면 **권한 상승(Elevate access)** 이 필요하다. 이 토글은 보안 설정이라 계정 소유자가 **직접** 켰고, 작업 뒤 해제된 것을 화면으로 확인했다(Entra 감사 로그: 09:57 상승, 11:02 해제).
- 권한 상승을 켜 두면 루트 범위 접근 권한이 생기므로, 쓴 뒤 꼭 끄는 것을 기록 습관으로 남긴다.

## 다음
- 역할 할당 실습(D4-02)은 아직 하지 않았다.
- 실습 리소스 그룹 두 개는 정리 목록에 올려 두었다(삭제는 직접 수행).
