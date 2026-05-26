# Peripheral-Multiple-Control-System

Basys3 보드(Xilinx Artix-7, XC7A35T)를 기준으로 설계 및 검증된 다기능 통합 제어 시스템입니다. 하드웨어 물리 입력과 PC의 UART 입력을 하나의 명령 체계로 통합하여, 시계, 스톱워치 및 외부 센서(초음파, 온습도)를 제어하고 결과를 출력합니다.

## 🛠 개발 환경 및 타겟 보드
* **OS:** Windows 11
* **개발환경:** VIVADO, VSCODE
* **Language:** Verilog
* **Target Board:** Basys3 (Xilinx Artix-7, XC7A35T)

## 👥 팀원 및 역할 (8조)
본 프로젝트는 8조 구성원들이 역할을 분담하여 진행했습니다.
* **이준형 (본인):** `ASCII SENDER`, `TX_FIFO`, `TX ARBITER`, `UART_TX` 설계 및 검증 담당.
* **윤지원:** `UART_RX`, `RX_FIFO`, `Decoder`, `Input Controller` 설계 및 검증 담당.
* **한정호:** `Control Unit`, `Display MUX` 설계 및 검증 담당.
* **장현동:** `FND Controller` 설계 및 검증 담당.

## 💡 지원 모드 및 기능
* **WATCH:** 시계값(기본 HH:MM) 표시.
* **STOPWATCH:** 스톱워치값 표시.
* **HCSR04:** 초음파 센서를 활용한 거리(cm) 표시.
* **DHT11:** 온습도 센서를 활용한 온도 정수값 표시.

## ⌨️ 통합 키 매핑 (Key Mapping)
Basys3 물리 입력과 PC(UART) 키 입력을 하나의 명령 체계로 통합합니다.
* **방향 제어 (U/D/R/L) & C버튼:** 모드 전환, 편집 자리 이동, 증가/감소, 리셋 기능 등을 수행합니다.
* **스위치 제어 (SW0, SW1, SW2):** 포맷 전환, 편집모드 토글, 락 제어 입력을 수행합니다.
* **PC 터미널 모니터링 (UART 조회):** `S`(FND 상태), `T`(스톱워치 전체값), `Y`(시계 전체값), `H`(초음파 거리값), `J`(DHT11 값)를 송신합니다.

## 🏗 시스템 데이터 패스 (Data Path)
* **PC TO FND:** `uart_rx` ➔ `ascii_decoder` ➔ `InputControl` ➔ `ControlUnit` ➔ `DisplayMux` ➔ `FndController`
* **FPGA TO FND:** `INPUTFPGA` ➔ `InputControl` ➔ `ControlUnit` ➔ `DisplayMux` ➔ `FndController`
* **PC TO PC:** `uart_rx` ➔ `ascii_decoder` ➔ `InputControl` ➔ `ControlUnit` ➔ `AsciiSender` ➔ `tx_fifo` ➔ `tx_arbiter` ➔ `uart_tx`
* **LOOPBACK:** `uart_rx` ➔ `rx_fifo` ➔ `tx_arbiter` ➔ `uart_tx`

## 📊 합성 및 구현 결과 (Implementation Reports)
* **Timing Report:** WNS(setup) 1.217 ns 달성.
* **Power Report:** Total On-Chip Power 0.098 W.
* **Utilization Report:** LUT 5.33%, FF 2.17%, IO 24.5% 사용.

## 🚀 트러블 슈팅 (Trouble Shooting)

### 1. 타이밍 위반 개선
* **문제 현상 및 원인:** 스탑워치/워치 카운터 경로에서 자릿수 연산이 집중되어 타이밍 마진이 부족했습니다.
* **조치 사항 및 개선 결과:** 스탑워치와 워치 카운터를 각 자릿수별 카운터 체인으로 분할했습니다. 경로 길이를 줄여 타이밍 위반을 해소했습니다.

### 2. DHT11 동작 안정화
* **문제 현상 및 원인:** 비동기성으로 인한 샘플링 오차로 DHT11 응답이 간헐적으로 불안정했습니다.
* **조치 사항 및 개선 결과:** DHT 데이터 라인에 동기 신호(synchronizer) 경로를 적용했습니다. 상태 전이 타이밍을 안정화해 DHT 동작 신뢰성을 확보했습니다.
