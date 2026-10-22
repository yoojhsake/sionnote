---
title: "[M365 Readiness] 실측 ③ SharePoint·OneDrive·M365 관리 센터 — 공유, 보존, 메시지 센터, 서비스 상태"
date: 2026-10-22 12:30:00 +0900
categories: [m365]
tags: [Readiness, 실측, SharePoint, OneDrive, 메시지 센터, 서비스 상태, 전체 기록]
excerpt: "외부 공유·기본 링크·보존·동기화·메시지 센터·서비스 상태 알림 등을 바꾸지 않고 읽어 판독한 결과와 근거, 개선 방안(미실행) 전체 기록"
---

측정일은 2026-10-22(목)이며 **모든 측정은 읽기 전용**입니다. 방법과 판독 기준은 [측정 방법 글]({{ "/m365/readiness-measurement-method/" | relative_url }})에 있습니다.

> 근거 표기: **조회** = 화면에서 직접 읽음 / **문서** = Microsoft Learn / **미확인** = 확인하지 못함. 테넌트 도메인과 사이트 주소는 게시하지 않았습니다. 개선 방안은 권고이며 **이번에 실행하지 않았습니다.**

## 1. 결과 한눈에

| 영역 | 읽은 값(조회) | 판독 |
|---|---|---|
| 외부 공유 수준 | SharePoint·OneDrive 모두 "누구나(Anyone)" = 최대 허용 | 위험 |
| Anyone 링크 만료 | 미설정 | 위험 |
| 기본 공유 링크 | 유형 "링크가 있는 모든 사용자", 권한 "편집" | 위험 |
| 저장소 | 1.24 TB 중 24 MB 사용(약 0.002%), 활성 사이트 10개 | 정상 |
| 삭제된 사이트 | 0건, 보존 93일 안내 | 정상 |
| 사이트 생성 | 사용자 생성 허용, 승인 절차 없음, 기본 시간대 UTC-08:00 | 주의 |
| 퇴사자 OneDrive 보존 | 삭제된 사용자 OneDrive 30일(허용 범위의 최소) | 주의 |
| OneDrive 동기화 | 도메인 제한 미설정, 파일 형식 차단 없음 | 주의 |
| 데이터 접근 거버넌스(DAG) 보고서 | 메뉴에 없음, 고급 관리 화면에는 평가판 등록 버튼만 | 측정 불가 |
| Restricted SharePoint Search | PowerShell 전용 | 측정 불가 |
| 메시지 센터 | 총 469건, 조치 기한 있는 31건 중 **기한 경과 16건**, 30일 내 임박 7건, 조직 내 상태 기록 3건 | 위험 |
| 서비스 상태 | 활성 문제 9건(인시던트 1, 권고 8), 이메일 알림 미설정 | 위험 |
| 지원 요청 | 서비스 요청 기록 0건 | 참고 |
| Customer Lockbox | "모든 데이터 액세스 요청에 승인 필요" 체크 해제 | 주의 |
| 릴리스 기본 설정 | 모두에게 공개하는 표준 릴리스 | 정상 |
| Copilot 라이선스 | 없음 | 해당 없음 |
| Agent 365 에이전트 | 레지스트리 346개, 소유자 없는 에이전트 0 | 정상 |
| Teams·Office 활성화 보고서 | "이 보고서에 대한 데이터가 없습니다" | 측정 불가 |
| M365 Apps 관리 센터 | 2회 시도 모두 로드 중 상태에서 멈춤 | 측정 불가 |
| Intune Windows 장치·업데이트 링 | 장치 0, 업데이트 링 0 | 측정 대상 없음 |

## 2. SharePoint·OneDrive 상세

### 2-1. 외부 공유 수준과 기본 링크
- **GUI 경로**: SharePoint 관리 센터 > 정책 > 공유
- **조회**: SharePoint와 OneDrive 슬라이더 모두 "누구나(Anyone)", Anyone 링크 만료 체크 해제. 기본 링크 유형 "링크가 있는 모든 사용자", 권한 "편집", 파일 "보기 및 편집", 폴더 "보기, 편집 및 업로드".
- **왜 문제인가**: 링크만 알면 로그인 없이 편집까지 가능한 링크가 **기본으로** 만들어집니다. 사용자는 보통 기본값을 그대로 쓰므로 실수로 넓게 공유될 가능성이 가장 큽니다. 슬라이더는 조직 최대치이고, 사이트별로 더 좁힐 수는 있지만 더 넓힐 수는 없습니다(문서).
- **개선 방안(미실행)**: 조직 수준을 "새 게스트와 기존 게스트"로 낮추거나, 최소한 Anyone 링크에 만료일(예: 수 주)과 "보기" 권한을 설정합니다. 기본 링크는 "특정 사용자"로 바꿉니다. 민감 사이트는 사이트별로 더 엄격하게, 민감도 레이블에 기본 공유 링크 동작을 묶는 방법도 있습니다.
- **주의**: 기본 링크 유형을 바꿔도 이미 만든 링크는 그대로입니다. 이미 만든 링크 점검은 별도 작업입니다(문서 설명, 이번에는 링크 목록을 측정하지 않음 → **미확인**).
- 근거: [외부 공유 켜기·끄기](https://learn.microsoft.com/sharepoint/turn-external-sharing-on-or-off), [공동 작업 옵션](https://learn.microsoft.com/sharepoint/collaboration-options), [기본 공유 링크 변경](https://learn.microsoft.com/sharepoint/change-default-sharing-link), [사이트별 외부 공유](https://learn.microsoft.com/sharepoint/change-external-sharing-site), [민감도 레이블의 기본 공유 링크](https://learn.microsoft.com/purview/sensitivity-labels-default-sharing-link)

### 2-2. 저장소와 사이트
- **조회**: 활성 사이트 화면 "1.24 TB 중 24.00 MB 사용", 활성 사이트 10개. 홈의 OneDrive 사용량 카드는 "지금은 이 정보를 가져올 수 없습니다"라고 나와 활성 사이트 화면을 근거로 삼았습니다. 삭제된 사이트 0건.
- **판독**: 용량 여유는 충분(정상). 샌드박스라 사용량이 거의 없는 것이며, 운영 값으로 해석하면 안 됩니다.
- **사이트 생성**: 사용자 생성 허용, 승인 절차 없음, 기본 시간대가 UTC-08:00(태평양)입니다. 국내 업무 기준과 달라 보고서 시간이 어긋날 수 있어 **주의**입니다. 사용자 만들기 허용 자체는 Teams 생성 권한과 함께 봐야 합니다([Identity 실측 글]({{ "/m365/readiness-measure-identity/" | relative_url }})의 그룹 생성 항목).

### 2-3. 퇴사자 OneDrive와 동기화
- **조회**: 삭제된 사용자 OneDrive 보존 30일(설정 범위의 최소), OneDrive 동기화는 특정 도메인 컴퓨터로 제한하는 옵션이 꺼져 있고 업로드 차단 파일 형식도 없음.
- **문제점**: 30일이 지나면 퇴사자 파일이 복구되지 않습니다. 인수인계 기간이 길거나 법적 보존 요구가 있으면 짧습니다. 동기화 도메인 제한이 없으면 개인 PC에도 회사 파일이 동기화될 수 있습니다.
- **개선 방안(미실행)**: 보존 기간을 업무 기준에 맞게 늘리고(범위 30~3650일), 조건부 액세스나 도메인 제한으로 동기화 가능한 기기를 한정합니다. 삭제 후 사이트·파일은 휴지통 단계(93일)가 별도로 있습니다.
- 근거: [OneDrive 보존·삭제](https://learn.microsoft.com/sharepoint/retention-and-deletion), [보존 기간 설정](https://learn.microsoft.com/sharepoint/set-retention), [OneDrive 개요](https://learn.microsoft.com/sharepoint/onedrive-overview), [동기화 계획](https://learn.microsoft.com/sharepoint/plan-file-sync)

### 2-4. 측정하지 못한 항목
| 항목 | 이유 | 재측정 방법 |
|---|---|---|
| DAG(데이터 접근 거버넌스) 보고서 | 보고서 메뉴에는 OneDrive 계정만 있고, 고급 관리 화면에 DAG가 포함 서비스로 나열되며 **무료 평가판 등록 버튼만** 있음 = SharePoint Advanced Management 미활성. 평가판 등록은 관리자 결정 사항이라 누르지 않음 | 라이선스 확보 후 보고서 생성(최대 며칠) |
| Restricted SharePoint Search | PowerShell 전용이고, 필요한 SPO 관리 셸이 Windows PowerShell 5.1 전용이라 Cloud Shell(PowerShell 7·Linux)에서 실행 불가 | 로컬 Windows PowerShell에서 SPO 관리자로 연결 후 조회 |

참고로 Restricted SharePoint Search는 **중단 예정**이며 2026-07-31부터 새로 켤 수 없고, 대안으로 Restricted Content Discovery를 쓰라는 안내가 문서에 있습니다. 이 테넌트는 측정 불가이므로 현재 값은 미확인입니다.
- 근거: [Restricted SharePoint Search](https://learn.microsoft.com/sharepoint/restricted-sharepoint-search), [데이터 접근 거버넌스 보고서](https://learn.microsoft.com/sharepoint/data-access-governance-reports), [SharePoint Advanced Management](https://learn.microsoft.com/sharepoint/advanced-management)

## 3. M365 관리 센터 상세

### 3-1. 메시지 센터
- **GUI 경로**: M365 관리 센터 > 상태 > 메시지 센터
- **조회**: 총 469건(수집 464건 기준 집계), 조치 기한이 있는 게시물 31건, **기한 경과 16건**(기한 범위 2026-06-29 ~ 2026-10-05), 30일 내 임박 7건. 조직 내 "예약됨 2, 시작됨 1"의 상태 기록 3건. 10/19 사전 조회 때는 451건이었습니다.
- **문제점**: 기한이 지난 변경 안내를 아무도 처리하지 않았습니다. 메시지 센터는 변경이 **오기 전 알려 주는** 채널이어서, 놓치면 사용자 문의로 먼저 알게 됩니다.
- **개선 방안(미실행)**: 담당자를 정하고 주 1회 검토, 메시지를 Planner 작업으로 보내 추적, 변경 영향이 큰 건은 변경 관리 문서로 연결. 환경 점검 보완 항목(메시지 센터 → Planner 연동)은 사용자 작업으로 남아 있습니다.
- 근거: [메시지 센터](https://learn.microsoft.com/microsoft-365/admin/manage/message-center), [메시지 센터 작업을 Planner로 추적](https://learn.microsoft.com/planner/track-message-center-tasks-planner), [M365 변경 가이드](https://learn.microsoft.com/microsoft-365-apps/best-practices/microsoft-365-change-guide)

### 3-2. 서비스 상태와 알림
- **조회**: 활성 문제 9건(인시던트 1: 사용자가 마이그레이션을 수행하지 못할 수 있음 / 권고 8). SharePoint Online 인시던트 1, Exchange 권고 2, M365 suite 권고 6. 이메일 알림은 **체크 해제**, 수신자 0.
- **문제점**: 장애가 나도 담당자가 먼저 알 방법이 없습니다. 문서상 이메일 알림은 사용자 지정 메뉴에서 켜고 주소는 최대 2개입니다.
- **개선 방안(미실행)**: 운영 담당 공용 사서함 + 담당자 1명으로 알림 설정. 알림은 인시던트와 권고를 구분해 받습니다.
- 근거: [서비스 상태 보기](https://learn.microsoft.com/microsoft-365/enterprise/view-service-health)

### 3-3. 릴리스 기본 설정, 지원 요청, Customer Lockbox
- **릴리스 기본 설정**: "모두에게 공개하는 표준 릴리스". 화면 배너에 **대상 릴리스는 2027년 1월 사용 중지**라는 안내가 있어, 대상 릴리스 사용자 지정 계획이 있다면 영향이 있습니다. 판독 정상.
- **지원 요청**: 서비스 요청 기록 0건("표시할 티켓이 없습니다"). 에스컬레이션 경로와 지원 계약(Services Hub)은 **미확인**.
- **Customer Lockbox**: "모든 데이터 액세스 요청에 승인 필요"가 해제. 이 기능은 승인자 역할과 라이선스 조건(문서상 E5 수준 서비스 설명 참고)이 있으며, 이 테넌트의 조건 충족 여부는 **미확인**. 설정 변경은 하지 않았습니다.
- 근거: [릴리스 옵션](https://learn.microsoft.com/microsoft-365/admin/manage/release-options-in-office-365), [릴리스 옵션 구성](https://learn.microsoft.com/microsoft-365/admin/manage/configure-release-options), [대상 릴리스 중지](https://learn.microsoft.com/microsoft-365/admin/manage/targeted-release-retirement), [Customer Lockbox 요청](https://learn.microsoft.com/purview/customer-lockbox-requests)

### 3-4. 에이전트와 Copilot
- Copilot 라이선스는 없음(해당 없음). Agent 365 개요에서 에이전트 레지스트리 346(작성자별 내역은 화면 해석이 불확실해 적지 않음), 소유자 없는 에이전트 0, 보류 요청 0, 예외 0 → 정상. 에이전트 사용 허용 대상 설정 화면은 **미확인**.

### 3-5. 보고서와 기기 영역
- 사용 현황 보고서(Teams, Office 정품 인증)는 "이 보고서에 대한 데이터가 없습니다" → **측정 불가**. 원인 후보는 보고서 생성 지연(약 48시간)과 샌드박스 활동 부족이며 확정하지 못했습니다.
- 이름 익명화(사용자·그룹·사이트 이름 숨기기)가 **켜져 있습니다.** 설정은 바꾸지 않았습니다.
- Intune Windows 장치 0, Windows 업데이트 링 0 → 측정 대상 없음. M365 Apps 관리 센터는 두 번 시도 모두 로딩에서 멈춰 측정 불가(원인 미확인).

## 4. 배운 점
- 외부 공유는 **조직 최대치 + 기본 링크 + 만료** 세 가지를 함께 봐야 합니다. 최대치가 Anyone이어도 기본 링크가 "특정 사용자"면 실수가 줄어듭니다.
- 메시지 센터와 서비스 상태는 "쓰지 않는 기능"이 아니라 **운영 업무의 입력**입니다. 담당과 주기가 없으면 위험으로 읽습니다.
- 라이선스나 로그인 환경이 맞지 않아 못 읽은 값은 "문제 없음"이 아니라 **측정 불가**로 적고 재측정 방법을 남깁니다.
