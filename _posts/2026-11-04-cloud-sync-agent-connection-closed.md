---
title: "[Troubleshooting] Cloud Sync 에이전트 로그에 연결 종료 오류가 반복되는데 동기화는 정상일 때"
date: 2026-11-04 16:30:00 +0900
categories: [iam, troubleshooting]
area: 하이브리드 동기화·에이전트
seq: 4
tags: [Troubleshooting, Entra Cloud Sync, 프로비저닝 에이전트, WebSocket, Windows 방화벽, TLS 1.3, 에이전트 로그]
excerpt: "에이전트 로그에 'forcibly closed by the remote host'가 1~2분마다 찍히는데 서비스는 Running이고 포털도 정상이었다. TLS 1.3 클라이언트를 꺼도 오류가 계속돼서 원인은 확인하지 못했다"
toc: true
last_modified_at: 2026-11-04 22:00:00 +0900
---

Cloud Sync 에이전트 서버의 로그를 열어 보니 "An existing connection was forcibly closed by the remote host"가 1~2분 간격으로 쌓이고 있었는데, 서비스는 Running이고 포털에서는 에이전트가 정상(활성)으로 표시됐습니다. 이 시간대의 요청 시 프로비전·동기화 결과는 따로 조회하지 않았습니다. 앞서 이 오류가 사라지는 것처럼 보였던 TLS 1.3 클라이언트 비활성은 이번 로그에서 그 설정을 유지한 채로도 오류가 계속 나와서 원인으로 단정할 수 없게 됐습니다.

## 요약

- 연결 종료 오류가 로그에 반복돼도 서비스·포털·동기화가 정상이면 에이전트가 재연결로 복구하는 것으로 보임
- TLS 1.3 클라이언트를 꺼 둔 서버에서도 같은 오류가 계속 나서 TLS 1.3이 원인이라고 말할 수 없음
- 오류 횟수보다 포털의 에이전트 상태와 실제 동기화 결과로 정상 여부를 판단해야 함

> 근거 표기: 조회 = 이 랩에서 직접 읽은 값 · 문서 = Microsoft Learn · 확인 불가 = 시도했지만 확인하지 못한 값(방법·사유 병기). 테넌트 ID·테넌트 도메인·클라우드 계정(UPN)은 가렸고, 개인 실습용 도메인(sionnote.local)의 계정 이름·장치 이름·호스트 이름은 그대로 보일 수 있습니다.

---

## 전체 기록

### 1. 증상

랩 서버(sionnote-sync01, Windows Server 2022)는 아웃바운드를 기본 차단하고 프로그램별로만 허용하며, Cloud Sync 에이전트와 Connect Sync가 함께 돌고 있습니다. 서버를 켜 둔 상태에서 에이전트 로그를 열었습니다.

- 최신 에이전트 로그(ProgramData 아래 Azure AD Connect Provisioning Agent\Trace)에 "forcibly closed by the remote host"가 883건, 그 가운데 최근 6000줄(약 3시간)에 142건이 있었음(조회)
- 로그 내용에 ConnectorSignalingWebSocket 관련 스택과 "ConnectorSignalingServiceHost ... Faulted state"가 함께 있었음(조회)
- 에이전트 서비스는 Running이고, 포털의 구성 개요에는 에이전트 1대 사용 중과 구성 상태 정상이 표시됨(조회)
- 포털의 에이전트 상태는 활성(2026-11-04 14:40 촬영)이며, 이 로그 시간대에 맞춘 프로비전·동기화 결과는 이 글에서 조회하지 않음

**포털에서 본 에이전트 상태(GUI)**: Entra 관리 센터 → Entra Connect → 클라우드 동기화 → 왼쪽 **에이전트**를 엽니다. "이 테넌트에 등록된 모든 에이전트" 목록에 `sionnote-sync01.sionnote.local` 한 대가 있고 상태가 **활성**입니다(조회, 2026-11-04 14:40, 외부 IP는 가림). 로그의 연결 종료 오류가 계속 쌓이는 서버인데도 포털 상태는 활성입니다(촬영 시점의 상태).

[![클라우드 동기화 에이전트 목록: sionnote-sync01 활성(GUI)]({{ "/assets/images/2026/11/cs-portal-gui-04-agents-active.png" | relative_url }})]({{ "/assets/images/2026/11/cs-portal-gui-04-agents-active.png" | relative_url }}){:target="_blank"}

화면의 출력을 옮겨 적었습니다(sync01, 2026-11-04 09:39, 아래 "오류 빈도 측정"의 명령과 서비스 상태 조회 결과).

```text
Enabled           : 0
DisabledByDefault : 1

AzureADConnectProvisioningAgent_20261103_<guid>.log

Wednesday, November 4, 2026 9:39:41 AM
forcibly count: 883
last match line: 37876

Name                          Status
----                          ------
AADConnectProvisioningAgent  Running
```

처음 두 줄(`Enabled`, `DisabledByDefault`)은 TLS 1.3 클라이언트 레지스트리 설정을 읽은 값입니다(아래 "TLS 1.3 클라이언트 설정").

<details markdown="1">
<summary>원본 캡처 보기 (PowerShell 화면, 해상도 낮음)</summary>

[![에이전트 로그에서 forcibly closed 검색]({{ "/assets/images/2026/11/hj-agent-log-forcibly.png" | relative_url }})]({{ "/assets/images/2026/11/hj-agent-log-forcibly.png" | relative_url }}){:target="_blank"}

</details>

### 2. 원인 및 분석

에이전트는 Azure Service Bus로의 지속적인 아웃바운드 연결로 클라우드의 동기화 요청을 기다립니다(문서). 기대값은 연결이 유지되거나 끊겨도 재연결로 복구되는 것이었습니다. 실제로는 연결이 반복해서 닫히는 기록이 쌓였지만, 서비스 Running과 포털의 활성 표시로 보아 에이전트 동작에는 영향이 없는 것으로 보입니다(추정).

<details markdown="1">
<summary>확인 과정 자세히 보기</summary>

#### 오류 빈도 측정

최신 로그 파일에서 문구를 센 결과입니다(조회).

```powershell
$p = 'C:\ProgramData\Microsoft\Azure AD Connect Provisioning Agent\Trace\AzureADConnectProvisioningAgent_20261103_<guid>.log'
(Select-String -Path $p -Pattern 'forcibly closed').Count          # 883
$t = Get-Content $p -Tail 6000
($t | Select-String 'forcibly closed').Count                       # 142
($t | Select-String 'DateTime=' | select -First 1).Line            # 첫 시각
($t | Select-String 'DateTime=' | select -Last 1).Line             # 마지막 시각
```

별도로 다시 읽은 최근 6000줄은 UTC 기준 11월 3일 21:31에서 11월 4일 00:42까지였습니다. 약 3시간 11분 동안 142건이어서 평균 1분 20초에 한 번 꼴입니다.

#### TLS 1.3 클라이언트 설정

SChannel의 TLS 1.3 클라이언트는 앞서 같은 서버에서 비활성으로 바꿔 두었고, 이번에도 그대로였습니다(조회).

```powershell
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Client' | fl Enabled,DisabledByDefault
# Enabled : 0   DisabledByDefault : 1
```

이 설정 변경과 그때의 관찰은 별도 글이나 캡처로 남기지 않았습니다. 그래서 이 글은 설정 상태(레지스트리 조회)와 이번 로그만 근거로 삼습니다. 앞서 설정을 바꿨을 때는 끄면 연결 종료 오류가 멈추고 다시 켜면 재발하는 것으로 보였지만(그때 관찰한 반복 횟수는 한두 번뿐), 이번 로그는 설정을 끈 상태에서도 오류가 이어졌습니다. 그 관찰이 우연이었는지, 다른 요인(서버 재부팅 시점, 연결 수명 등)이 겹쳤는지는 분리하지 못했습니다.

#### 방화벽 상태

아웃바운드 기본 차단에 프로그램 기준 허용 규칙을 쓰는 구성입니다. 에이전트 서비스 실행 파일(AADConnectProvisioningAgent.exe)과 업데이터에 TCP 80/443 허용 규칙이 있고(조회, Connect Sync 글의 LAB- 규칙 목록), 에이전트가 동작하는 것으로 보아 연결 자체는 열려 있습니다. `연결이 닫히는 쪽이 방화벽인지 원격 서비스인지는 이 로그만으로는 알 수 없습니다. 참고로 [Connect Sync 글]({{ "/iam/connect-sync-install-firewall/" | relative_url }}) 7절의 5157 집계에서 이 서비스 실행 파일(`aadconnectprovisioningagent.exe`)의 443 차단 기록은 11-03 08:45~08:53의 10건이 마지막입니다(조회). 다만 이 글의 로그 시간대(11-04 06:31~09:42 KST)에 차단 감사가 켜져 있었는지는 확인하지 않아서, 로컬 방화벽 차단이 없었다는 근거로는 쓰지 않습니다.`

</details>

### 3. 결론

(추정) 에이전트의 WebSocket 연결이 반복해서 닫히고(로그 문구는 remote host가 닫았다고 표시, 조회) 에이전트가 재연결로 복구하는 것으로 보임. 닫는 쪽은 확인 불가. 서비스 Running과 포털 활성 상태는 조회.

확인 불가가 둘 있습니다. 하나는 연결이 닫히는 원인(시도: 로그 빈도 측정, TLS 1.3 설정 확인, 사유: 닫는 쪽 서비스와 네트워크 경로의 로그를 볼 수 없음)이고, 다른 하나는 앞서 TLS 1.3 클라이언트를 끈 뒤 오류가 멈춘 것처럼 보였던 이유입니다(시도: 같은 설정으로 로그 재확인, 사유: 이번 로그에서는 설정 상태와 무관하게 오류가 나서 설명할 수 없음).

### 4. 권고방안

1. 정상 여부는 로그의 오류 횟수가 아니라 포털의 에이전트 상태(사용 중)와 실제 결과로 판단합니다. 요청 시 프로비전 한 건을 돌려 반영되는지 확인하면 가장 빠릅니다.
2. 에이전트가 격리(quarantine)되거나 동기화가 멈추면 그때 로그 시각을 구성의 프로비전 로그와 맞춰 봅니다. 서비스를 재시작하는 것은 마지막 수단으로 두세요.
3. TLS 1.3 클라이언트 비활성을 정답으로 적용하지 마세요. 이번 관찰로는 효과를 입증하지 못했고, 시스템 전체의 보안 설정이 바뀝니다.

관련 글: [Connect Health 에이전트 설치가 마지막 단계에서 실패하고 되돌려질 때]({{ "/iam/troubleshooting/health-agent-install-rollback/" | relative_url }}) · [Cloud Sync로 하이브리드 조인 구성하기]({{ "/iam/hybrid-join-cloud-sync/" | relative_url }})

### 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (4건)</summary>

- **문서**: 에이전트는 Azure Service Bus로 지속적인 아웃바운드 연결을 유지하며 클라우드 요청을 기다림
    - 출처: [Cloud sync deep dive - how it works](https://learn.microsoft.com/entra/identity/hybrid/cloud-sync/concept-how-it-works)
- **조회**: 에이전트 로그의 forcibly closed 883건, 최근 6000줄 142건, 로그의 시각 범위, 서비스 Running
    - 출처: sionnote-sync01 (2026-11-04 오전)
- **조회**: SChannel TLS 1.3 클라이언트 Enabled=0, DisabledByDefault=1
    - 출처: sionnote-sync01 (레지스트리)
- **확인 불가**: 이 설정을 바꿨을 때의 앞선 관찰(끄면 오류가 멈추고 켜면 재발한 것으로 보였던 것). 방법: 당시 캡처·로그 확인, 사유: 남겨 두지 않았음. 이 글의 결론에는 쓰지 않음

</details>
