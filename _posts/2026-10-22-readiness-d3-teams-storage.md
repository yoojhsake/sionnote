---
title: "[M365 Readiness] D3 Teams 저장 구조 — 채널 유형별 파일 위치"
date: 2026-10-22 09:40:00 +0900
categories: [m365]
tags: [Readiness, D3, Teams, SharePoint, 채널]
excerpt: "표준·비공개·공유 채널의 파일이 어디에 저장되는지 Graph 조회로 확인한 기록"
---

수행일은 2026-10-22이고, 프로그램 일정상 D3(Teams 저장 구조) 주제입니다.

## 목표
Team과 채널을 만들고, 채널 유형(표준·비공개·공유)에 따라 파일이 저장되는 SharePoint 위치가 어떻게 다른지 확인한다.

## 절차
1. Teams에서 **Practice-Team-01**을 만든다(비공개 Team).
2. 채널 3개를 만든다: ch-standard(표준), ch-private(비공개), ch-shared(공유).
3. Cloud Shell에서 Graph로 채널 목록과 각 채널의 파일 폴더 주소를 조회한다.
4. 각 폴더에 시험 파일 업로드를 시도해 결과 코드를 기록한다.

![표준 채널은 팀 사이트 폴더, 비공개·공유 채널은 별도 사이트에 파일이 저장되고, 시험 업로드 결과가 표시됨]({{ "/assets/images/2026/10/d3-channel-storage.png" | relative_url }})
*그림 1. 채널 유형별 파일 위치와 시험 업로드 결과*

## 실제 값
![Teams 관리 센터 Manage teams 화면. 8 teams, Practice-Team 행이 표준 채널 2, 비공개 채널 1]({{ "/assets/images/2026/10/d3-manage-teams.png" | relative_url }})
*그림 2. Teams 관리 센터 팀 목록 (빨간 상자: Practice-Team-01, 일부 팀 이름은 가림)*

| 항목 | 값 |
|---|---|
| Team 수 | 7개 → 8개 (기존 기록의 "6개"는 오류였고 조회 결과 7개) |
| Practice-Team-01 채널 | General + ch-standard + ch-private + ch-shared (Graph 조회 4개) |
| 관리 센터 열 값 | 표준 채널 2, 비공개 채널 1 (공유 채널은 두 열에 잡히지 않음) |
| 표준 채널 파일 폴더 | 팀 사이트 `/sites/Practice-Team-01`의 문서 라이브러리 안 폴더 |
| 비공개 채널 파일 폴더 | 별도 사이트 `/sites/Practice-Team-01-ch-private` |
| 공유 채널 파일 폴더 | 별도 사이트 `/sites/Practice-Team-01-ch-shared` |
| 시험 업로드 | 표준 201 성공 / 비공개 403 / 공유 403 |

## 막힌 곳과 미확인
- 비공개·공유 채널 업로드가 403인 **원인은 미확인**이다. 관리자가 해당 채널의 구성원이 아니어서일 가능성이 있지만 확인하지 않았다.
- 공유 채널이 관리 센터의 채널 수 열에 어떻게 집계되는지는 이 화면만으로는 알 수 없다.

## 다음
- 채널 구성원 상태와 403의 관계를 확인한다.
- Practice-Team-01은 정리 목록에 올려 두었다(삭제는 하지 않음, 삭제 시 30일간 복구 가능).

> 테넌트 도메인은 사이트 주소에서 뺐습니다.
