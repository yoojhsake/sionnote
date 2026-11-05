---
title: "[IAM] Hyper-V로 하이브리드 ID 실습 환경 구성하기"
date: 2026-11-02 20:10:00 +0900
categories: [iam]
phase: 하이브리드 실습
seq: 1
tags: [IAM, Hyper-V, 실습 환경, 가상 스위치, 체크포인트, vTPM]
excerpt: "내부 스위치 하나와 NAT 스위치 하나, 2세대 VM 4대로 AD·Entra 하이브리드 실습망을 만들었다. 도메인 컨트롤러(ad01)는 외부로 나가는 길이 없고, 체크포인트로 단계마다 되돌릴 수 있게 했다"
toc: true
last_modified_at: 2026-11-04 22:00:00 +0900
---

온프레미스 AD와 Entra ID를 연결하는 실습을 한 대의 PC에서 반복하려고 Hyper-V로 작은 망을 만들었습니다. 도메인 컨트롤러·동기화 서버·클라이언트 2대를 내부 스위치에 묶고, 인터넷으로 나가는 통로는 도메인 컨트롤러만 막고 동기화 서버와 클라이언트 2대에만 열어 두었습니다. 단계마다 체크포인트를 남겨서 어느 지점으로든 되돌릴 수 있습니다.

## 요약

- 스위치는 내부(lab-internal)와 NAT(Default Switch) 두 개이며, 외부 인터넷 경로는 ad01만 없고 sync01·cl10·cl11이 NAT로 가짐
- 실습 VM 4대는 모두 2세대이고(구성 버전 12.0은 6대 모두), 클라이언트 중 Win11만 가상 TPM을 켬
- 이 구성 차이와 뒤 글의 `TpmProtected` 값 차이(NO/YES)가 일치함(추정: TPM만 켜고 끄는 비교는 하지 않았고 두 PC는 Windows 10/11도 다름)

> 근거 표기: 조회 = 이 랩에서 직접 읽은 값 · 문서 = Microsoft Learn · 확인 불가 = 시도했지만 확인하지 못한 값(방법·사유 병기). 테넌트 ID·테넌트 도메인·클라우드 계정(UPN)은 가렸고, 개인 실습용 도메인(sionnote.local)의 계정 이름·장치 이름·호스트 이름은 그대로 보일 수 있습니다.

---

## 전체 기록

### 1. 목표

하이브리드 조인과 Entra 조인을 AD 구축부터 끝까지 실습하되, 실패하면 직전 상태로 돌아가 다시 해 볼 수 있는 환경을 만듭니다. 실제 회사망처럼 "기본 차단, 필요한 프로그램만 허용"하는 방화벽 조건도 걸어 둡니다.

전체 구성을 먼저 그림으로 보면 이렇습니다. 숫자는 아래 표에서 조회한 값입니다.

<picture><source media="(max-width: 640px)" srcset="{{ "/assets/images/2026/11/lab-network-topology-m.png" | relative_url }}"><img src="{{ "/assets/images/2026/11/lab-network-topology.png" | relative_url }}" alt="Hyper-V 실습망 구성도: 내부 스위치와 NAT 스위치, 네 대의 VM" loading="lazy"></picture>

### 2. 개념

가상 스위치는 VM이 서로, 그리고 호스트와 통신하게 해 주는 소프트웨어 스위치입니다. 종류에 따라 갈 수 있는 곳이 달라집니다(문서).

| 종류 | 연결되는 곳 | 이 실습에서의 쓰임 |
|---|---|---|
| 외부(External) | 호스트의 물리 NIC를 통해 실제 망 | 사용하지 않음(조회: 스위치 목록에 없음) |
| 내부(Internal) | 같은 호스트의 VM끼리, 그리고 호스트와 VM | `lab-internal`: AD·DNS 등 도메인 통신 전용 |
| 개인(Private) | 같은 호스트의 VM끼리만 | 사용하지 않음 |
| 기본 스위치(Default Switch) | NAT로 호스트를 거쳐 인터넷 | sync01과 클라이언트의 외부 통신(조회) |

세대는 만든 뒤에 바꿀 수 없고, 2세대는 UEFI·보안 부팅·vTPM을 지원합니다(문서). Windows 11은 UEFI와 TPM이 필요해서 2세대가 필요하고, 나머지 VM도 같은 세대로 맞췄습니다.

### 3. 결과

#### 3-1. 가상 스위치

가상 스위치 관리자(Hyper-V 관리자 → 가상 스위치 관리자)에서 스위치별 속성을 봅니다. 호스트 PC 이름, NIC 모델, MAC 주소 범위는 가렸습니다.

[![가상 스위치 관리자: lab-internal(내부 네트워크)]({{ "/assets/images/2026/11/hv-01-vswitch-lab-internal.png" | relative_url }})]({{ "/assets/images/2026/11/hv-01-vswitch-lab-internal.png" | relative_url }}){:target="_blank"}

[![가상 스위치 관리자: Default Switch(기본 네트워크)]({{ "/assets/images/2026/11/hv-01-vswitch-default.png" | relative_url }})]({{ "/assets/images/2026/11/hv-01-vswitch-default.png" | relative_url }}){:target="_blank"}

| 스위치 | 유형 | 비고(조회) |
|---|---|---|
| lab-internal | 내부 네트워크 | VLAN ID 미사용, 호스트 NIC와 연결 안 됨 |
| Default Switch | 기본 네트워크(NAT) | Hyper-V가 NAT를 자동 제공 |

#### 3-2. 가상 머신

실습에 쓰는 VM 4대와, 이번 시리즈에서 쓰지 않는 VM 2대(꺼짐)입니다.

| VM | 역할 | 세대 | vCPU | 시작 RAM | NIC가 연결된 스위치 |
|---|---|---|---|---|---|
| sionnote_ad01 | 도메인 컨트롤러·DNS | 2 | 2 | 4096MB | lab-internal |
| sionnote_sync01 | Connect Sync·Cloud Sync·Health 에이전트 | 2 | 2 | 2048MB | lab-internal + Default Switch |
| sionnote_cl10 | Windows 10 클라이언트 | 2 | 8 | 4096MB | lab-internal + Default Switch |
| sionnote_cl11 | Windows 11 클라이언트 | 2 | 8 | 4096MB | lab-internal + Default Switch |
| sionnote_exchange01, sionnote_mecm01 | 이번 시리즈 범위 아님(꺼짐) | - | - | - | - |

- 구성 버전은 6대 모두 12.0입니다(조회).

#### 3-3. 주소 계획과 IP 구성(두 서버에서 조회)

이 시리즈의 글과 명령에서는 IP 값을 싣지 않고 아래 변수 이름으로 적습니다. 따라 해 볼 때는 자기 환경과 겹치지 않는 사설 /24 대역을 하나 정해 `LAB_NET`으로 쓰고, 아래 호스트 번호(마지막 자리)를 그 대역 안에서 고정 IP로 부여하면 됩니다.

| 변수 | 대상 | 정하는 방법 | 비고 |
|---|---|---|---|
| `LAB_NET` | lab-internal 대역 | 직접 정한 사설 /24(서브넷 마스크 255.255.255.0) | 호스트·외부 망과 연결되지 않는 내부 스위치용 |
| `DC_IP` | ad01 | `LAB_NET`의 호스트 번호 10 | DC 조회 결과의 IPv4 |
| `SYNC_IP` | sync01 | `LAB_NET`의 호스트 번호 40 | 고정 IP |
| `CL10_IP` · `CL11_IP` | cl10 · cl11 | `LAB_NET`의 호스트 번호 51 · 52 | 고정 IP |
| `NAT_IP` · `NAT_GW` | Default Switch 쪽 주소·게이트웨이 | 정하지 않음 | 호스트의 Hyper-V NAT가 정해 주는 값이라 `Get-NetIPConfiguration`으로 조회합니다 |

| 서버 | lab-internal 쪽 | Default Switch 쪽 |
|---|---|---|
| ad01 | `DC_IP` | 없음(NIC가 lab-internal 한 개뿐) |
| sync01 | `SYNC_IP`/24, DNS는 `DC_IP` | `NAT_IP`/20, 게이트웨이 `NAT_GW` |

- Default Switch 쪽 주소는 호스트가 VM마다 나눠 주기 때문에 VM마다 다릅니다. sync01과 cl11의 NAT 쪽 주소를 각각 조회했을 때 두 주소와 게이트웨이가 모두 같은 /20 대역 안에 있었습니다(조회). 호스트가 다시 시작하면 값이 바뀔 수 있어(추정: 호스트가 자동 부여하는 값이라서) 글에 값을 고정해 적지 않았습니다.

- ad01은 외부로 나가는 NIC가 없어 인터넷 접근이 원천적으로 막힙니다. Microsoft 클라우드와 통신하는 쪽은 NAT 쪽 NIC가 있는 sync01(과 클라이언트 2대)이고, 그중 서버 쪽 통신은 sync01이 맡습니다.
- 클라이언트(cl10·cl11)는 NIC가 두 개이지만, 도메인 통신은 lab-internal(`CL10_IP`·`CL11_IP`)로 합니다.

### 4. 운영 판단

- 내부 스위치를 쓴 이유: 호스트 NIC와 분리되어 집·회사 망에 영향이 없고, AD의 DNS·DHCP 같은 서비스를 마음대로 켜도 안전합니다.
- NAT 스위치를 sync01과 클라이언트에만 붙인 이유: 클라우드와 통신해야 하는 쪽만 밖으로 열고, DC는 닫아 두기 위함입니다. 방화벽은 sync01에서 기본 차단 + 프로그램별 허용으로 추가로 제한합니다(다음 글에서 이어짐).
- 체크포인트: ad01은 `AD-promoted-baseline` → `before-connect-sync` → `evidence-connect-sync-on-DC-blocked`, sync01은 `baseline-domainjoined-fw-block` → `pre-connect-sync-install` → `before-connect-sync-configure`로 남겼습니다(조회). 이름만 보면 어느 시점인지 알 수 있게 짓는 것이 편했습니다.

### 5. 절차

#### 5-1. VM 만들기(ad01 예시)

Hyper-V 관리자 → 동작 → 새로 만들기 → **가상 컴퓨터**로 마법사를 엽니다. ad01을 만들 때의 입력값입니다(조회: 당시 캡처).

| 마법사 페이지 | 입력값 | 고른 이유 |
|---|---|---|
| 이름 및 위치 지정 | 이름 `sionnote_ad01`, 위치는 기본값 대신 실습용 폴더 | VM 파일을 한 곳으로 모아 관리 |
| 세대 지정 | **2세대** | 만든 뒤에는 세대를 바꿀 수 없음(마법사 경고, 문서 동일) |
| 메모리 할당 | 시작 4096MB, **동적 메모리 사용** 체크 | 켜 둔 VM 여러 대가 호스트 메모리를 나눠 쓰게 함 |
| 네트워킹 구성 | `lab-internal` | DC는 내부 스위치에만 연결 |
| 가상 하드 디스크 연결 | 새로 만들기 `sionnote_ad01.vhdx`, 60GB | 동적 확장 VHDX라 실제 사용량만큼만 차지 |
| 설치 옵션 | 부팅 가능 이미지 Windows Server 평가판 ISO | Windows Server 평가판 설치 |

[![새 가상 컴퓨터 마법사: 이름과 위치]({{ "/assets/images/2026/11/hv-wiz-01-name.png" | relative_url }})]({{ "/assets/images/2026/11/hv-wiz-01-name.png" | relative_url }}){:target="_blank"}

[![새 가상 컴퓨터 마법사: 세대 지정]({{ "/assets/images/2026/11/hv-wiz-02-generation.png" | relative_url }})]({{ "/assets/images/2026/11/hv-wiz-02-generation.png" | relative_url }}){:target="_blank"}

[![새 가상 컴퓨터 마법사: 메모리 할당(동적 메모리 체크)]({{ "/assets/images/2026/11/hv-wiz-03-memory.png" | relative_url }})]({{ "/assets/images/2026/11/hv-wiz-03-memory.png" | relative_url }}){:target="_blank"}

[![새 가상 컴퓨터 마법사: 네트워킹 구성]({{ "/assets/images/2026/11/hv-wiz-04-network.png" | relative_url }})]({{ "/assets/images/2026/11/hv-wiz-04-network.png" | relative_url }}){:target="_blank"}

[![새 가상 컴퓨터 마법사: 가상 하드 디스크 연결]({{ "/assets/images/2026/11/hv-wiz-05-disk.png" | relative_url }})]({{ "/assets/images/2026/11/hv-wiz-05-disk.png" | relative_url }}){:target="_blank"}

[![새 가상 컴퓨터 마법사: 설치 옵션]({{ "/assets/images/2026/11/hv-wiz-06-install.png" | relative_url }})]({{ "/assets/images/2026/11/hv-wiz-06-install.png" | relative_url }}){:target="_blank"}

[![새 가상 컴퓨터 마법사: 요약]({{ "/assets/images/2026/11/hv-wiz-07-summary.png" | relative_url }})]({{ "/assets/images/2026/11/hv-wiz-07-summary.png" | relative_url }}){:target="_blank"}

#### 5-2. 만든 직후 설정 확인과 변경

마법사는 vCPU 수를 묻지 않습니다. VM을 만든 뒤 Hyper-V 관리자에서 VM을 선택하고 **설정**을 열어 확인하고 고칩니다(2026-11-02 촬영, 호스트 PC 이름과 폴더 경로는 가렸습니다).

먼저 **펌웨어** 화면입니다. 2세대 VM이라 UEFI 펌웨어를 쓰고, 부팅 순서는 DVD 드라이브(설치 ISO) → 네트워크 어댑터 → 하드 드라이브입니다. 왼쪽 목록에는 보안(보안 부팅 사용), 메모리 4096MB, 프로세서 8개, SCSI 컨트롤러의 VHDX와 DVD, 네트워크 어댑터 `lab-internal`이 한눈에 보입니다. 이 시점의 프로세서는 기본값인 **8개**였습니다.

[![VM 설정 > 펌웨어: 부팅 순서와 하드웨어 목록(GUI)]({{ "/assets/images/2026/11/hv-set-01-firmware.png" | relative_url }})]({{ "/assets/images/2026/11/hv-set-01-firmware.png" | relative_url }}){:target="_blank"}

ad01은 DC 한 대라 vCPU를 **프로세서** 화면에서 2개로 줄였습니다. 왼쪽 목록의 프로세서 항목이 "2개 가상 프로세서"로 바뀐 것이 변경 결과입니다.

[![VM 설정 > 프로세서: 가상 프로세서 수를 2로 지정(GUI)]({{ "/assets/images/2026/11/hv-set-02-processor.png" | relative_url }})]({{ "/assets/images/2026/11/hv-set-02-processor.png" | relative_url }}){:target="_blank"}

#### 5-3. 만든 뒤 확인하는 경로

1. Hyper-V 관리자 → 동작 → **가상 스위치 관리자**에서 스위치 이름·유형을 확인합니다.
2. VM 선택 → **설정**에서 펌웨어(UEFI), 보안(보안 부팅·TPM), 메모리, 프로세서, SCSI 컨트롤러(디스크 경로), 네트워크 어댑터(연결된 스위치)를 차례로 봅니다. 설정 창 맨 위 드롭다운으로 VM을 바꿔 가며 확인할 수 있습니다.
3. 체크포인트는 VM 선택 후 하단 **검사점** 패널에서 트리로 확인합니다.

[![ad01의 검사점 트리(Hyper-V 관리자 하단 검사점 패널)]({{ "/assets/images/2026/11/hv-02-checkpoints-ad01.png" | relative_url }})]({{ "/assets/images/2026/11/hv-02-checkpoints-ad01.png" | relative_url }}){:target="_blank"}

[![sync01의 검사점 트리]({{ "/assets/images/2026/11/hv-02-checkpoints-sync01.png" | relative_url }})]({{ "/assets/images/2026/11/hv-02-checkpoints-sync01.png" | relative_url }}){:target="_blank"}

### 6. 막힌 곳

- 가상 스위치 관리자를 열려고 작업 창 링크를 눌렀는데 아무 창도 뜨지 않았습니다. 다른 창이 그 위치를 덮고 있었고, 상단 메뉴 **동작 → 가상 스위치 관리자**로 열자 해결됐습니다.

### 7. 정리·남은 일

- cl10에는 가상 TPM이 꺼져 있고(보안 화면의 "신뢰할 수 있는 플랫폼 모듈 사용" 해제), cl11에는 켜져 있습니다. 뒤 글에서 보게 될 `TpmProtected` NO/YES 차이와 이 설정 차이는 일치합니다. 설정 값은 Hyper-V 관리자에서 읽었고(조회), 설정 차이가 값 차이의 원인이라는 연결은 추정입니다. cl10의 TPM을 켜서 다시 비교해 보는 것은 하지 않았습니다.
- 다음 글: 도메인 컨트롤러(ad01) 구축.


### 부록. 사용한 명령과 출력

이 글의 VM·스위치 값은 모두 Hyper-V 관리자 GUI에서 읽었고 스크립트는 쓰지 않았습니다. 서버 안의 IP 구성만 아래 명령으로 읽었습니다(sync01에서 실행한 결과). 출력의 IP 값은 위 주소 계획의 변수 이름으로 바꿔 적었습니다(표기용 치환). 열 이름·인터페이스 이름·접두 길이는 원본 그대로입니다.

```powershell
Get-NetIPAddress -AddressFamily IPv4 | ? IPAddress -notmatch '^127|^169' | Select InterfaceAlias,IPAddress,PrefixLength | ft -AutoSize
Get-DnsClientServerAddress -AddressFamily IPv4 | ? ServerAddresses | Select InterfaceAlias,ServerAddresses | ft -AutoSize
Get-NetRoute -DestinationPrefix 0.0.0.0/0 | Select InterfaceAlias,NextHop,RouteMetric | ft -AutoSize
```

```text
InterfaceAlias IPAddress       PrefixLength
-------------- ---------       ------------
Ethernet 2     <SYNC_IP>                 24
Ethernet       <NAT_IP>                  20

InterfaceAlias ServerAddresses
-------------- ---------------
Ethernet       {<NAT_GW>}
Ethernet 2     {<DC_IP>}

InterfaceAlias NextHop       RouteMetric
-------------- -------       -----------
Ethernet       <NAT_GW>                0
```

## 근거 자료

<details markdown="1">
<summary>근거 자료 펼쳐 보기 (6건)</summary>

- (조회) 가상 스위치 2개와 유형: Hyper-V 관리자 → 가상 스위치 관리자
- (조회) VM별 세대·vCPU·메모리·NIC·보안: Hyper-V 관리자 → 각 VM 설정
- (조회) ad01·sync01 IP와 DNS: 각 서버 관리자 PowerShell (`Get-NetIPAddress`, `Get-DnsClientServerAddress`)
- (문서) [Hyper-V 가상 스위치 만들기·구성](https://learn.microsoft.com/windows-server/virtualization/hyper-v/get-started/create-a-virtual-switch-for-hyper-v-virtual-machines)
- (문서) [Hyper-V 네트워킹 계획(스위치 종류)](https://learn.microsoft.com/windows-server/virtualization/hyper-v/plan/plan-hyper-v-networking-in-windows-server)
- (문서) [1세대·2세대 VM 선택](https://learn.microsoft.com/windows-server/virtualization/hyper-v/plan/should-i-create-a-generation-1-or-2-virtual-machine-in-hyper-v) · [동적 메모리 개요](https://learn.microsoft.com/windows-server/virtualization/hyper-v/dynamic-memory)

</details>
