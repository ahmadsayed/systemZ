# System Z

## Trials with Qemu on Windows 

Installation
```
c:\Program Files\qemu\qemu-system-s390x.exe" -machine s390-ccw-virtio -cpu max,zpci=on -serial mon:stdio -display none -m 4096 -nic user,model=virtio,hostfwd=tcp::2222-:22 --cdrom ubuntu-18.04.5-server-s390x.iso  -kernel kernel.s390 -initrd initrd.s390 -drive file=z.img,if=none,id=virtio-disk0,format=raw,cache=none -device virtio-blk-ccw,devno=fe.0.0001,drive=drive=virtio=disk0,id=virtio-disk0,bootindex=1
```

Booting user netoworking

```
"c:\Program Files\qemu\qemu-system-s390x.exe" -machine s390-ccw-virtio -cpu max,zpci=on -serial mon:stdio -display none -m 4096 -nic user,model=virtio,hostfwd=tcp::2222-:22  -drive file=z.img,if=none,id=virtio-disk0,format=raw,cache=none -device virtio-blk-ccw,devno=fe.0.0001,drive=virtio-disk0,id=virtio-disk0,bootindex=1
```

Configure TAP Network still not able to figure out networking, looks like I need to try it on Linux attached to switch via Lan

```
"c:\Program Files\qemu\qemu-system-s390x.exe"  -machine s390-ccw-virtio -smp 4 -cpu max,zpci=on -serial mon:stdio -display none -m 4096 -netdev tap,id=mynet0,ifname=TAP -device virtio-net-ccw,netdev=mynet0 -drive file=z.img,if=none,id=virtio-disk0,format=raw,cache=none -device virtio-blk-ccw,devno=fe.0.0001,drive=virtio-disk0,id=virtio-disk0,bootindex=1     
```

## Trials with Hercules

Here I followed a mix of those two tutorials

* https://www.youtube.com/watch?v=QTBNt32ERWE&t=651s
* https://astr0baby.wordpress.com/2018/06/03/installing-ubuntu-18-04-server-s390x-in-hercules-mainframe-simulator/

Also I did some updates in networking from my side, and Important note, in order to make it works I need to follow the below build steps because newer version of Hercules cause an issue while chroot / and fail the installation

### Workable Configuration with Hercules  Ubuntu 18.04

Need the latest version of hercules but th very recent version has an issue after checking it out switch to older commit 

```
#!/bin/bash


# Clone the Repo
git clone https://github.com/hercules-390/hyperion.git
# Revert to older version before Jan 2019
git checkout 3be22dd2e2fd6aa0e0e9a354aec63224569b12d5
# create empty build directly
mkdir build
cd build
# run cmake and make to perform a build
cmake ..
make
make install
```

#### Create Disk
```
# this create something similar to thin disk in vmware, still thick disk can be created
dasdinit -z -lfs -linux ubuntu.disk 3390-9 LIN120
```

#### Conf file
```
ARCHMODE z/Arch
ALRF ENABLE
CCKD RA=2,RAQ=4,RAT=2,WR=2,GCINT=5,GCPARM=0,NOSTRESS=0,TRACE=0,FREEPEND=-1
CNSLPORT 3270
CONKPALV (3,1,10)
CPUMODEL 3090
CPUSERIAL 012345
DIAG8CMD ENABLE
ECPSVM YES
LOADPARM 0A95DB..
LPARNAME HERCULES
MAINSIZE 1024
MOUNTED_TAPE_REINIT DISALLOW
NUMCPU 4
OSTAILOR Z/OS
PANRATE 80
PGMPRDOS LICENSED
SHCMDOPT NODIAG8
SYSEPOCH 1900
TIMERINT 50
TZOFFSET +1400
YROFFSET 0

# Display Terminals

0700 3270
0701 3270

# dasd
0120 3390 ./dasd/ubuntu.disk

# network                               s390     realbox
0A00,0A01  CTCI -n /dev/net/tun -t 1500 10.1.1.2 10.1.1.1
```


#### Networking

```
#!/bin/bash
iptables -F INPUT
iptables -F OUTPUT
iptables -F FORWARD
iptables -t nat -A POSTROUTING -o ens160 -s 10.1.1.0/24 -j MASQUERADE
iptables -A FORWARD -s 10.1.1.0/24 -j ACCEPT
iptables -A FORWARD -d 10.1.1.0/24 -j ACCEPT
echo 1  /proc/sys/net/ipv4/ip_forward
echo 1  /proc/sys/net/ipv4/conf/all/proxy_arp
sysctl -w net.ipv4.ip_forward=1
sysctl net.ipv4.conf.eth0.forwarding=1
```


## Installing OpenShift on Hercules

Even if recommended in OpenShif is to create z/VM and get a VM to each node, I do not think running z/VM on emulator will be effecient.

My approach will be as follow 
 * Create Emulator for each node, those nodes are connected to each other via same tunnl --> Tested and Working
 * bring a standard Machine and make it DNS on the same VPC and insure it is accessible from the z Machines --> Tested and Working
 * create a Loadbalancer in the host machines where all emulators run --> Not yet tested
 * In OpenShift installation I need kernel, initramfs, and parmfile and PUNCH it to the Mainframe I believe I can use something similar to the following mentioned in [Gentoo Installation Guide](https://wiki.gentoo.org/wiki/S390/Hercules)
 ```
CPUSERIAL 002623        # CPU serial number
CPUMODEL  2098          # CPU model number
MAINSIZE  1024           # Main storage size in megabytes
XPNDSIZE  0             # Expanded storage size in megabytes
CNSLPORT  3270          # TCP port number to which consoles connect
NUMCPU    2             # Number of CPUs
LOADPARM  0120....      # IPL parameter
OSTAILOR  LINUX         # OS tailoring
PANRATE   SLOW          # Panel refresh rate (SLOW, FAST)
ARCHMODE  ESAME         # Architecture mode ESA/390 or ESAME

# .-----------------------Device number
# |     .-----------------Device type
# |     |       .---------File name and parameters
# |     |       |
# V     V       V
#---    ----    --------------------

#---    ----    --------------------

# console
001F    3270

# terminal
0009    3215

# reader
000C    3505    ./rdr/netboot-s390x-kernel-20141003 ./rdr/gentoo.parmfile ./rdr/netboot-s390x-initramfs-20141003 autopad eof

# printer
000E    1403    ./prt/print00e.txt crlf

# dasd
0120    3390    ./dasd/3390.LINUX.0120

# tape
0581    3420

# network                               s390     realbox
```
