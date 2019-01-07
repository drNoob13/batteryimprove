# [Linux] Improving battery life + reducing heat generation of ultra-thin laptops with 6+ physical-core CPU



## Preface

This post discusses a combined method to extend battery life of high-end laptops with 6-core or 9-core Intel CPUs while reducing the heat generation at the same time. The method sets CPU peformance differently depending on the power source (AC or battery) and uses TLP as a frontend for automation.
 
 
### Summary

* Intel p_state driver
* Completely software method (will not harm your hardware)
* Intel processors with 6+ physical cores
* Adjust perf for dynamic frequency downscaling, thus significantly reduce power consumption + heat
* Disable unused CPU cores to maximize battery (not necessary for laptops with high-capacity battery)
* Disable unused hardware in battery mode (ethernet/bluetooth..)
* Can be used in tandem with other methods such as reducing CPU operating voltage (undervolt) or changing thermal conductivity substance (repaste)
 
 
##### Test Spec
[System76 Oryx Pro 4](https://system76.com/laptops/oryx)
```
OS: Ubuntu 18.04.1 LTS x86_64 
Host: Oryx Pro oryp4
Kernel: 4.15.0-38-generic 
Uptime: 34 mins 
Packages: 2525 
Shell: bash 4.4.19 
Resolution: 1920x1080 
DE: GNOME 3.28.3 
WM: GNOME Shell 
WM Theme: Adwaita 
Theme: Adwaita-dark [GTK2/3] 
Icons: Ubuntu-mono-dark [GTK2/3] 
Terminal: gnome-terminal 
CPU: Intel i7-8750H (12) @ 2.200GHz 
GPU: Intel Integrated Graphics (HD 630)
GPU: NVIDIA GeForce GTX 1070 Mobile 
Memory: 2639MiB / 31997MiB
Drive: 01 500GB M2 SSD + 01 256GB M2 SSD
```

##### Battery:
```
15" built-in display @ 144Hz: Embedded 4 Cells Polymer battery pack – 55Wh (57.1Wh max)    
```

### Results:

`powerstat` is used to evaluate the battery discharge rate of different profiles.

| Method  | Discharge rate | CPU Temp. | Load | Method Description |
| ------------- | ------------- | ------------- | ------------- | ------------- |
| 1  | 11.64W | 38-40C| Light load: `gnome-system-monitor`, `powerstat`, `powertop`, background: Google Chrome (1 tab), `psensor`| Intel GPU + this combined method + backlight display @ 15% |
| 2  | 16.41W  | 41-43C | Light load: `gnome-system-monitor`, `powerstat`, `powertop`, background: Google Chrome (1 tab), `psensor`| Intel GPU + TurboBoost disable + perf:19%-50% + original config + backlight display @ 15% |
| 3  | 23.56W | 48-50C | Light load: `gnome-system-monitor`, `powerstat`, `powertop`, background: Google Chrome (1 tab), `psensor`| nvidia GPU (GTX 1070 max-q) + TurboBoost disable + perf:19%-50% + original config + backlight display @ 15% |
| 4 | 9.11W | 36C | No load (idle) | Intel GPU + this combined method + backlight display @ 15% |

*Note: I used [system76-power](https://github.com/pop-os/system76-power) to disable the nvidia GPU.*

While `powertop` reports the current recharge rate per process at the moment, it is not accurate to use it to measure the total power consumption. A tool that statistically measures the power consumption over a long period of time (7-10 minutes) will produce more reliable results. In this end, we use `powerstat`.

From the evaluation, method 1 can help oryx4 laptop last about 5 hours under light load (I often got 5h - 5.2h). While method 4 can prolong the laptop battery to 6 hours in idle (a convenient test case for different profiles, not practical use case). 

![Method 1 and Method 2](https://github.com/drNoob13/batteryimprove/blob/master/Profiling/method-1_and_method-2.png)
![Method 3 and Method 4](https://github.com/drNoob13/batteryimprove/blob/master/Profiling/method-3_and_method-4.png)


### Prerequisites

* Intel p_state driver

### Optional (but recommended)

* [TLP](https://linrunner.de/en/tlp/docs/tlp-linux-advanced-power-management.html) to automate the setting below.
* powertop (one should not run `powertop --auto-tune` at start-up to avoid conflict with TLP).


## Method Explained

To extend battery life, I use the following combined methods:

* Enable dynamic frequency down-scaling based on performance profile in Intel p_state.
* Disable unnecessary services/processes that adversely affect the battery life.
* Automate the process with `tlp`.
* Reduce the number of operational cores in battery mode. (manually run after startup)
* Tuning with `powertop`.

### Enable dynamic frequency down-scaling (runtime)

Instead of manual underclocking the CPU, I use a dynamic method to down-scale the CPU frequency by setting the maximum and minimum performance allowed in AC and battery.

Require: an active intel p_state driver (power governor = powersave(default))
         (to check: `cat /sys/devices/system/cpu/intel_pstate/status`)

**Battery Mode**:
```bash
echo 20 | sudo tee /sys/devices/system/cpu/intel_pstate/max_perf_pct
echo 20 | sudo tee /sys/devices/system/cpu/intel_pstate/min_perf_pct
echo  1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo
```
*Explain*: Set the maximum performance allowed equal to 19% of the highest possible performance. The Intel p_state driver will down-scale the CPU frequency accordingly. This can be executed at run-time. 
* max-performance <- 20/100 is equivalent to set maximum CPU freq @ 800MHz  (intel i7-8750H)
* min-performance <- 20/100 is equivalent to set minimum CPU freq @ 800MHz (intel i7-8750H)
* Turbo Boost <- disable

**Note**: You should experiment and try different `max_perf_pct value` and see what best suits your need. Suggest: if you are using in battery mode, try first with a value between 20-30%. If you are on AC, try a value between 70-90%.


**AC Mode**:
```bash
echo 80 | sudo tee /sys/devices/system/cpu/intel_pstate/max_perf_pct
echo 20 | sudo tee /sys/devices/system/cpu/intel_pstate/min_perf_pct
echo  0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo
```
*Explain*: Set the maximum performance allowed equal to 80% of the highest possible performance. The Intel p_state driver will down-scale the CPU frequency accordingly. This can be executed at run-time.
* max-performance \<- 80/100 is equivalent to set maximum CPU freq @ 3400MHz (intel i7-8750H)
* min-performance \<- 20/100 is equivalent to set minimum CPU freq @ 800MHz  (intel i7-8750H)
* Turbo Boost \<- enable

With these setting, the maximum CPU temperature is 40C (light load + no TurboBoost) on battery and 75-80C (high load + TurboBoost) with AC plugged in. Refer to [this post](https://www.reddit.com/r/linux/comments/9nv46i/underclocking_highend_mobile_cpus_for_cooler/) for the relation between frequency and temperature.

To automate the process, I use TLP. You can find my TLP config [here](https://github.com/drNoob13/batteryimprove/blob/master/tlp)

*Please read thru the config before applying. Also, I encourage you to peruse the tlp document [here](https://linrunner.de/en/tlp/docs/tlp-configuration.html)*

### Disable unnecessary processes

#### Disable Bluetooth (started with TLP at startup)

To disable bluetooth when on battery, change the following line in your TLP config:

```DEVICES_TO_DISABLE_ON_STARTUP="bluetooth"```

#### Disable Ethernet (runtime)

Ethernet consumes huge energy when it is used (12-14W) and considerable energy (0.5-1W) when it is not used/idle. To turn off your ethernet, refer to `ifconfig` for the ethernet interface name, then kill it

```bash
sudo ifconfig enp4s0 down
```
*Note*: ethernet could be on idle (i.e. no cable hooked up), but `powertop` would report it as in full utilization.

Refer to the bash script (execute after restart on battery): [here](https://github.com/drNoob13/batteryimprove/blob/master/run_bat_powersave.sh)

### Disable unused CPU cores (runtime)

I found out that I never utilized all my CPU cores in battery mode. Since my goal was to keep my laptop's battery from draining, I never ran any computationally expensive programs without an AC plugged. Therefore, it is helpful for me to disable few CPU cores on battery mode. It hasn't introduced any perceived performance drop since I only ran simple programs such as VI text editor, 4 or 5 Chrome tabs, LibreOffice, etc.

To disable 4/6 physical cores in i7-8750H (don't worry, they will become online if you explicitly enable them back on or after restart)

```bash
echo 0 | sudo tee /sys/devices/system/cpu/cpu11/online
echo 0 | sudo tee /sys/devices/system/cpu/cpu10/online
echo 0 | sudo tee /sys/devices/system/cpu/cpu9/online
echo 0 | sudo tee /sys/devices/system/cpu/cpu8/online
echo 0 | sudo tee /sys/devices/system/cpu/cpu7/online
echo 0 | sudo tee /sys/devices/system/cpu/cpu6/online
echo 0 | sudo tee /sys/devices/system/cpu/cpu5/online
echo 0 | sudo tee /sys/devices/system/cpu/cpu4/online
```

Replace `echo 0` by `echo 1` if you want to turn these CPU cores back on.

Refer to the bash script (execute after restart on battery) [here](https://github.com/drNoob13/batteryimprove/blob/master/run_bat_powersave.sh). 


### Tuning with powertop (runtime)

* Often it requires a calibration `powertop --calibrate` on battery for an extended period of time before you can start to tune.
* Run `powertop --auto-tune` to let powertop tweak the bad processes that are eating your battery.
* Refer to [reference](https://wiki.archlinux.org/index.php/powertop).
* This should be done manually. Do not run `powertop --auto-tune` at startup to avoid conflict with TLP.
----

Hope it helps.
