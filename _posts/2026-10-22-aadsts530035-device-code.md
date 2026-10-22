---
title: "[트러블슈팅] Cloud Shell에서 Exchange Online 로그인 시 AADSTS530035"
categories: [m365, troubleshooting]
tags: [Exchange Online, PowerShell, Entra, 보안 기본값, AADSTS530035]
excerpt: "Connect-ExchangeOnline -Device가 막힌 원인과 우회하지 않고 해결하는 방법"
---

## 증상
Azure Cloud Shell(PowerShell 7)에서 `Connect-ExchangeOnline -Device`로 코드 입력 후 관리자 계정을 선택하면
"이에 대한 액세스 권한이 없습니다" 화면과 함께 **오류 코드 530035**가 표시된다.

![로그인 후 이에 대한 액세스 권한이 없습니다 화면과 문제 해결 세부 정보. 오류 코드 530035]({{ "/assets/images/2026/10/530035-error.png" | relative_url }})
*그림 1. 오류 화면 (계정·Request Id·Correlation Id·IP는 가림)*

오류 상세에는 앱 이름이 *Microsoft Exchange REST API Based Powershell*, 디바이스 상태가 *Unregistered*로 나온다.

## 원인
Microsoft Learn의 오류 코드 표에서 AADSTS530035는 **BlockedBySecurityDefaults**, 즉 보안 기본값이 요청을 차단한 것이다.
보안 기본값은 device-code 로그인 흐름을 막는다. 이 테넌트는 조건부 액세스 정책이 없고 보안 기본값이 켜져 있어 일치한다.

![Cloud Shell의 device-code 로그인이 보안 기본값에 막혀 530035가 나오는 경로와 대안]({{ "/assets/images/2026/10/aadsts530035-flow.png" | relative_url }})
*그림 2. 오류가 나온 경로와 대안*

조건부 액세스 화면에서 정책 목록이 비어 있는 것을 확인했다(읽기만 함).

![Microsoft Entra 조건부 액세스 정책 화면. 등록된 정책 없이 예시 템플릿만 표시됨]({{ "/assets/images/2026/10/ca-policies.png" | relative_url }})
*그림 3. 조건부 액세스 정책 화면 (상단 계정 정보는 가림)*

## 해결 방향 (설정을 바꾸지 않는 선택지)
1. **본인 PC의 PowerShell**에서 `-Device` 없이 브라우저 로그인으로 연결한다.
2. 보안 기본값을 끄고 조건부 액세스로 전환하는 방법도 있으나 **보안 설정 변경**이므로 관리자·보안팀 결정 사항이다.

## 배운 점
- 오류 코드(AADSTS 번호)를 먼저 공식 표에서 찾으면 원인이 바로 좁혀진다.
- Request Id를 Entra 로그인 로그에서 조회하면 적용된 정책을 확인할 수 있다.
- 막혔을 때 우회하지 않고 **원인·대안·결정권자**를 기록하는 것이 운영 기록으로 더 가치가 있다.

> 이 글의 Request Id·계정·도메인 값은 게시하지 않았습니다.
