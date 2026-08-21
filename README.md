# ON DEVICE AI FPGA FINAL PROJECT

## 1. 프로젝트 개요 (Project Overview)
- **프로젝트명**: ON DEVICE AI FPGA FINAL PROJECT
- **개발 일자**: 2026-02-23
- **개발 팀**: 8조
- **타겟 보드**: Basys3 Board (Xilinx Artix-7, XC7A35T)
- **개발 환경**: Windows 11, VIVADO, VSCODE
- **사용 언어**: Verilog

---

## 2. 팀원 및 역할 (Team Roles)
| 이름 | 역할 및 담당 모듈 | 테스트벤치(TB) 담당 |
|---|---|---|
| **윤지원** | Rx, Rx_Fifo, Decoder, Input Controller | Input Controller |
| **한정호** | Control Unit, Display MUX | Control Unit |
| **이준형** | ASCII SENDER, TX_FIFO, TX ARBITER, TX | ASCII SENDER, ARBITER |
| **장현동** | FND Controller | Blink 기능 |

---

## 3. 주요 기능 및 모드 (Key Features & Modes)
본 프로젝트는 Basys3의 물리적 입력(버튼/스위치)과 PC의 UART 키 입력을 하나의 명령 체계로 통합하여 제어합니다.

### 지원 모드 (Supported Modes)
| 모드 값 | 이름 | FND 표시 내용 |
|:---:|---|---|
| **0** | **WATCH** | 시계값 (기본 HH:MM, 포맷 전환 시 SS:CS) |
| **1** | **STOPWATCH** | 스톱워치값 (리셋 후 기본 상태 RUN) |
| **2** | **HCSR04** | 초음파 센서 측정 거리 (cm) |
| **3** | **DHT11** | 온도/습도 정수값 |

### 락(Lock) 동작 정의
- **락 해제 시 (oModeLock=0)**: 모드 순환(R), 로컬 리셋(L), 모드별 기본 동작 수행.
- **락 설정 시 (oModeLock=1)**: 모드가 고정되며, 각 모드별 특수 동작(편집 자리 전환, 자동 측정 토글 등)을 수행.

---

## 4. 통합 입력 매핑 (Input Mapping)
Basys3 하드웨어 입력과 PC UART 입력은 `InputControl` 모듈을 통해 동일한 명령 체계로 정규화됩니다.

### 버튼 및 UART 매핑
| 동작 명령 | Basys3 물리 입력 | UART 입력 (PC) | 상세 동작 설명 |
|:---:|:---:|:---:|---|
| **Up** | BTN_U | `U` / `u` | Watch/Stopwatch 편집 시 증가 |
| **Down** | BTN_D | `D` / `d` | Watch/Stopwatch 편집 시 감소, 센서 모드 수동 1회 측정 |
| **Right** | BTN_R | `R` / `r` | 락 해제 시 다음 모드로 전환. 락 설정 시 모드별 특수 동작 (자리 전환 또는 자동 측정 토글) |
| **Left** | BTN_L | `L` / `l` | 현재 모드의 로컬 리셋 (Local Reset) |
| **Center** | BTN_C | `C` / `c` | 소프트 글로벌 리셋 (Watch 모드로 복귀) / 하드웨어 즉시 초기화 |
| **Format** | SW0 펄스 | `1` | Watch/Stopwatch 표시 포맷 전환 (HH:MM ↔ SS:CS) |
| **Edit** | SW1 펄스 | `2` | Watch/Stopwatch 편집 모드 진입/해제 토글 |
| **Lock** | SW2 레벨 | `3` | 모드 락(Lock) 상태 토글 |

### UART 전용 출력(조회) 매핑
| 키 입력 | 기능 명칭 | 설명 |
|:---:|---|---|
| **S** | SHOW_FND | 현재 FND에 표시되는 값 문자열 송신 |
| **T** | SHOW_STOPWATCH | 스톱워치의 전체 데이터 송신 |
| **Y** | SHOW_WATCH | 시계의 전체 데이터 송신 |
| **H** | SHOW_HCSR04 | 초음파 센서 거리값 송신 |
| **J** | SHOW_DHT11 | DHT11 센서 값 송신 |

---

## 5. 시스템 아키텍처 및 데이터 패스 (System Architecture & Datapath)

### 📌 전체 블록 구성 (TOP Block Diagram)

```text
+-----------------------+                    +------------------------------------+
|  PC KEYBOARD (UART)   | ---> [ uart_rx ] ->|           ascii_decoder            | --+
+-----------------------+                    +------------------------------------+   |
                                                                                      |
+-----------------------+                    +------------------------------------+   |
| BUTTONS/SW (Basys3)   | -----------------> |             INPUTFPGA              | --+
+-----------------------+                    +------------------------------------+   |
                                                                                      v
                                                     +------------------------------------+
                                                     |            INPUTCONTROL            |
                                                     +------------------------------------+
                                                                      |
                                                                      v
+-----------------------+                    +------------------------------------+
|  SENSOR CORES         | -----------------> |            ControlUnit             |
|  (HCSR04, DHT11)      |                    +------------------------------------+
+-----------------------+                       |                              |
                                                v                              v
                                     +--------------------+         +---------------------+
                                     |     DisplayMux     |         |     AsciiSender     |
                                     +--------------------+         +---------------------+
                                                |                              |
                                                v                              v
                                     +--------------------+         +---------------------+
                                     |   FndController    |         |  tx_fifo / arbiter  |
                                     +--------------------+         +---------------------+
                                                |                              |
                                                v                              v
                                     +--------------------+         +---------------------+
                                     |    FND DISPLAY     |         |  PC TERMINAL (TX)   |
                                     +--------------------+         +---------------------+
```

### 5.1 PC to FND
```text
[PC UART] -> uart_rx -> ascii_decoder -> InputControl -> ControlUnit -> DisplayMux -> FndController -> [FND]
```

### 5.2 FPGA to FND
```text
[Buttons/Switches] -> INPUTFPGA -> InputControl -> ControlUnit -> DisplayMux -> FndController -> [FND]
```

### 5.3 PC to PC (상태 조회)
```text
[PC UART] -> uart_rx -> ascii_decoder -> InputControl -> ControlUnit -> AsciiSender -> tx_fifo -> tx_arbiter -> uart_tx -> [PC Terminal]
```

### 5.4 LoopBack
```text
[PC UART] -> uart_rx -> rx_fifo -> tx_arbiter -> uart_tx -> [PC Terminal]
```

---

## 6. 핵심 모듈 상세 (Module Details)

### 6.1 Control Unit (중앙 제어부)
- 공통 명령 인터페이스를 각 기능 코어에 분배하고 표시 데이터를 취합합니다.
- **내부 코어**: `WatchCore`, `StopwatchCore`, `SensorControlUnit`, `Hcsr04Core`, `Dht11Core`

### 6.2 UART TX/RX (송수신부)
- **AsciiSender**: 시계, 스톱워치, 센서 등 서로 다른 코어의 데이터 비트 폭을 통합하고, 이를 ASCII 문자열 형태로 변환(Formatting)하여 출력합니다.
- **tx_arbiter**: TX 채널의 Busy 상태를 확인하며, `AsciiSender`의 전송 데이터와 `rx_fifo`의 Loopback 데이터 간의 전송 우선순위를 중재합니다.

### 6.3 Display & Output (디스플레이 출력부)
- `DisplayMux`: 현재 모드에 따라 FND에 표시할 데이터 소스를 선택합니다. 센서의 원시 데이터(Raw binary)를 FND 표시에 적합한 BCD 포맷으로 변환하는 기능도 수행합니다.
- `FndController`: `GlobalTickGen`에서 생성된 1kHz 스캔 틱과 2Hz 점멸 틱을 기반으로 4자리 Active-Low FND를 다이나믹 스캔 방식으로 구동합니다.

---

## 7. 테스트 및 검증 (Testbench & Verification)
각 하위 모듈 단위 검증 및 TOP 레벨 통합 검증을 진행했습니다.

- **주요 검증 항목**:
  - UART 명령 시퀀스(R, 1, 2, 3...)에 따른 FSM 상태 전환(WATCH ➔ STOPWATCH 등) 정상 동작 확인.
  - 디바운싱(Debounce) 회로 및 버튼/PC 입력 우선순위 중재 로직 동작 확인.
  - 센서(HCSR04, DHT11)의 10us 트리거 생성, 40비트 데이터 수신 및 체크섬 파형 검증.

---

## 8. 성능 리포트 (Performance Reports)

| 항목 | 결과 (Result) | 상세 내용 |
|---|---|---|
| **전력 소모 (Power)** | **0.098 W** | Dynamic: 0.026 W (27%), Static: 0.072 W (73%) |
| **타이밍 (Timing)** | **Met** | WNS (Setup): 1.217 ns, WHS (Hold): 0.085 ns (Failing Endpoints: 0) |
| **자원 사용량 (Utilization)** | **LUT: 5.33%** | LUT: 1108 / 20800, FF: 902 / 41600 (2.17%), IO: 26 / 106 (24.5%) |

---

## 9. 트러블슈팅 (Troubleshooting)

| 문제 현상 | 원인 분석 | 해결 방안 및 결과 |
|---|---|---|
| **타이밍 위반 (Timing Violation)** | 스톱워치 및 워치 카운터 모듈 내에서 자릿수 연산 로직이 길어지면서 타이밍 마진(Slack)이 부족해짐 | 전체 카운터를 **각 자릿수별 카운터 체인으로 분할**하여 조합 논리 경로의 길이를 단축. 결과적으로 모든 Timing Constraint를 만족(Met)함. |
| **DHT11 통신 불안정** | 센서 데이터 라인(1-wire)의 비동기적 특성으로 인해 샘플링 오차가 발생하여 응답을 놓치거나 깨짐 | DHT 데이터 입력 라인에 **동기화 회로(Synchronizer)**를 추가하여 상태 전이 타이밍을 시스템 클럭에 안정적으로 동기화함으로써 신뢰성 확보. |