
# LTESniffer (Docker Environment)

This repository provides a Docker-based environment to build and run **LTESniffer** for:
- **Downlink sniffing** (single USRP)
- **Uplink sniffing** (multi-USRP branch)

> Tested on Ubuntu 18.04/20.04/22.04.  
> **Important:** Uplink decoding requires **GPSDO lock** on both USRP B200/B210 devices.

---

## Repository Structure

```

LTESniffer-docker/
├─ Dockerfile
├─ docker-compose.yml
├─ LTESniffer/            # (optional) local copy or submodule
├─ LTESniffer-multi/      # (optional) local copy or submodule
└─ uhd/                   # (optional) local copy or submodule

```

Depending on how your Dockerfile is written, the build may:
- `git clone` sources during image build, OR
- use the local folders mounted into the container.


## Requirements (Host)

- Docker Engine
- Docker Compose
- USRP connected (B210 via USB 3.0 recommended)

### Check Docker
```bash
docker --version
docker-compose --version
````

---

## Quick Start

### 1) Build and start container

```bash
cd ~/LTESniffer-docker
sudo systemctl start docker
docker-compose up -d --build
```

### 2) Enter the container

```bash
docker-compose exec ltesniffer bash
```

---

## UHD (>= 4.0)

LTESniffer requires UHD version **>= 4.0**.

### Download USRP firmware/images

Inside the container:

```bash
sudo uhd_images_downloader
```

### Verify UHD installation

```bash
uhd_config_info
```

### Detect connected USRP devices

```bash
uhd_find_devices
```

Example output:

```
-- UHD Device 0
Device Address:
  ->serial: 3125XXX
  product: B210
  type: b200
```

---

## Build LTESniffer

> If your Docker image already builds LTESniffer during `docker-compose up --build`,
> you can skip the manual build steps below.

### A) Downlink build (main branch)

Inside the container:

```bash
cd /workspace/LTESniffer
mkdir -p build && cd build
cmake ..
make -j4
```

### B) Uplink build (multi-USRP branch)

Inside the container:

```bash
cd /workspace/LTESniffer-multi
git checkout LTESniffer-multi-usrp
mkdir -p build && cd build
cmake ..
make -j4
```

---

## Uplink: Configure USRP Serials (Required)

For uplink decoding, you must configure the serial numbers of both USRP devices in:

```
src/src/LTESniffer_Core.cc
```

### 1) Find serial numbers

Inside the container:

```bash
uhd_find_devices
```

### 2) Edit `LTESniffer_Core.cc`

Look for lines similar to:

```cpp
std::string rf_a_string = "clock=gpsdo,num_recv_frames=512,recv_frame_size=8000,serial=3113D1B";
std::string rf_b_string = "clock=gpsdo,num_recv_frames=512,recv_frame_size=8000,serial=3125CB5";
```

Replace the `serial=` values with your two USRP serials.

### 3) Rebuild

```bash
cd /workspace/LTESniffer-multi/build
make -j4
```

---
## srsRAN 추가 설정
빌드 디렉토리 들어가서 
```
sudo make install
srsran_install_configs.sh user
```
하기

## Run LTESniffer

> **Downlink** uses 1 USRP.
> **Uplink** requires 2 USRPs and GPSDO lock.

### Downlink example

```bash
cd /workspace/LTESniffer/build
sudo ./src/LTESniffer -A 1 -W 4 -f 1840e6 -C -m 1
```

### Uplink (multi-USRP) example

```bash
cd /workspace/LTESniffer-multi/build
sudo ./src/LTESniffer -A 2 -W 4 -f 1840e6 -u 1745e6 -C -m 1
```

---

## Uplink: GPSDO Lock Procedure (Required)

LTESniffer requires **GPSDOs on both USRP B200/B210 devices** to be locked before uplink decoding works correctly.

### Step 1) Run once (initial cell search)

```bash
sudo ./src/LTESniffer -A 2 -W 4 -f <DL_Freq> -u <UL_Freq> -C -m 1
```

You may see a warning (expected before lock):

```
Could not lock reference clock source. Sensor: gps_locked=false
```

### Step 2) Stop and wait for lock

* Stop with **Ctrl + C** after the cell search finishes.
* Wait until both devices are locked (may take ~10 minutes depending on GPS signal).
* On some devices, the LED near the GPSDO port indicates lock status.

### Step 3) Run again to decode uplink

```bash
sudo ./src/LTESniffer -A 2 -W 4 -f <DL_Freq> -u <UL_Freq> -C -m 1
```

---

## Troubleshooting

### Docker daemon not running

```bash
sudo systemctl start docker
```

### Permission denied to Docker socket

```bash
sudo usermod -aG docker $USER
# logout/login required
```

### USRP not detected

* Check USB 3.0 connection
* Try:

```bash
uhd_usrp_probe
```

---

## Notes

* This repository does **not** provide legal guidance. Ensure you have proper authorization before capturing or analyzing cellular signals.

```

