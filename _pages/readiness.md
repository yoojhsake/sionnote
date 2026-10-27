---
title: "M365·Azure 기록 목차"
permalink: /readiness/
author_profile: true
---

M365·Azure 운영 사전 프로그램의 기록을 **작업 순서대로** 모았습니다. 각 글은 상단에 요약, 하단에 전체 과정(풀버전)이 있습니다. 새 글이 생기면 이 표에 번호를 이어서 추가합니다.

## 1. 준비와 구조 이해

| 번호 | 글 | 다루는 내용 |
|---|---|---|
| 00 | [사전작업]({{ "/m365/readiness-prework/" | relative_url }}) | 환경 점검, 조회 전용 |
| 01 | [D1 M365 구조]({{ "/m365/readiness-d1-m365-structure/" | relative_url }}) | 라이선스는 서비스 플랜 묶음 |
| 02 | [D2 Identity 구조]({{ "/m365/readiness-d2-identity-groups/" | relative_url }}) | 동적 그룹, 그룹 라이선스 |
| 03 | [D3 Teams 저장 구조]({{ "/m365/readiness-d3-teams-storage/" | relative_url }}) | 채널 유형별 파일 위치 |
| 04 | [D4 Azure 구조]({{ "/m365/readiness-d4-azure-structure/" | relative_url }}) | 계층, 리소스 그룹, Elevate access |
| 05 | [트러블슈팅 AADSTS530035]({{ "/m365/troubleshooting/aadsts530035-device-code/" | relative_url }}) | 로그인 차단 원인과 선택지 |

## 2. 운영 설정 실측

| 번호 | 글 | 다루는 내용 |
|---|---|---|
| 06 | [측정 방법과 4단계 판독]({{ "/m365/readiness-measurement-method/" | relative_url }}) | 읽기 전용 원칙, 판독 기준, 전체 분포 |
| 07 | [실측 ① Identity·Entra]({{ "/m365/readiness-measure-identity/" | relative_url }}) | 관리자, MFA, 조건부 액세스, 게스트 |
| 08 | [실측 ② Teams]({{ "/m365/readiness-measure-teams/" | relative_url }}) | 정책, 외부 액세스, 회의 |
| 09 | [실측 ③ SharePoint·관리 센터]({{ "/m365/readiness-measure-sharepoint-admin/" | relative_url }}) | 공유, 보존, 메시지 센터 |
| 10 | [실측 ④ Purview·Azure 거버넌스]({{ "/m365/readiness-measure-purview-azure/" | relative_url }}) | 감사, DLP, Policy, 구독 권한 |

## 3. 재확인과 트러블슈팅 (10/23~10/27)

| 번호 | 글 | 다루는 내용 |
|---|---|---|
| 11 | [10/23 재확인 기록]({{ "/m365/readiness-recheck/" | relative_url }}) | "확인 불가"로 남겼던 항목을 다시 시도한 결과, 변경 4건과 원복 방법 |
| 12 | [트러블슈팅 관리 그룹 설정 403]({{ "/m365/troubleshooting/mg-settings-403-elevate-refresh/" | relative_url }}) | Elevate를 켜도 안 읽힐 때 토큰 갱신 |
| 13 | [트러블슈팅 채널 파일 업로드 403 재현]({{ "/m365/troubleshooting/channel-upload-403-repro/" | relative_url }}) | 표준·비공개·공유 채널 결과 비교 |
| 14 | [Cloud Shell에서 Graph 호출, 되는 것과 안 되는 것]({{ "/m365/troubleshooting/cloud-shell-graph-scope/" | relative_url }}) | 토큰 범위에 따라 갈리는 조회 결과 |
| 15 | [트러블슈팅 상황별 대처 가이드]({{ "/m365/troubleshooting/troubleshooting-playbook/" | relative_url }}) | 403·로그인 차단·토큰 범위·반응 지연을 상황별로 정리 |
