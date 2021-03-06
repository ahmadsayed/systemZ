# z/Architecture Emulators


Experimenting installing OCP and Linux on Z platform, with Emulations currently having two emulators
* [qemu-system-s390x](https://wiki.qemu.org/Documentation/Platforms/S390X)
* [Hercules-390](http://www.hercules-390.org/)

### General notes: 

The following Benchmark done for Hercules, qemu and IBM Hyper Protect Virtual Server, running Linux One ubuntu 18.04

Interestingly Qemu has more facilities than Hercules and outperform Hercules, but Hercules support KVM 


#### Hercules CPU 

```
CPU: SHA256-hashing 500 MB
    284.661 seconds
CPU: bzip2-compressing 500 MB
    271.677 seconds
CPU: AES-encrypting 500 MB
    19.429 seconds
```
### Qemu CPU 

```
CPU: SHA256-hashing 500 MB
    18.163 seconds
CPU: bzip2-compressing 500 MB
    66.803 seconds
CPU: AES-encrypting 500 MB
    38.001 seconds
```

### IBM Z Virtual machine on KVM
```
CPU: SHA256-hashing 500 MB
    2.532 seconds
CPU: bzip2-compressing 500 MB
    6.933 seconds
CPU: AES-encrypting 500 MB
    0.351 seconds

```

## Emulating z/Arch on Rasperry PI

#### Raspberry PI 3 B+
Successfully compiled Hercules on Raspberry PI 3 B+, and run MVS 3.8 
Not able to successfully install  Ubuntu 18.04 

#### Raspberry PI 4 B (8 GB)
Failed to compile Hercules 
Failed to install ubuntu on qemu-system-s390x

## Trials with Qemu on Windows 

Installation
```
qemu-system-s390x.exe -machine s390-ccw-virtio -cpu max,zpci=on -serial mon:stdio -display none -m 4096 -nic user,model=virtio,hostfwd=tcp::2222-:22 --cdrom ubuntu-18.04.5-server-s390x.iso  -kernel kernel.s390 -initrd initrd.s390 -drive file=z.img,if=none,id=virtio-disk0,format=raw,cache=none -device virtio-blk-ccw,devno=fe.0.0001,drive=virtio-disk0,id=virtio-disk0,bootindex=1
```

Booting after installation

```
qemu-system-s390x.exe -machine s390-ccw-virtio -cpu max,zpci=on -serial mon:stdio -display none -m 4096 -nic user,model=virtio,hostfwd=tcp::2222-:22  -drive file=z.img,if=none,id=virtio-disk0,format=raw,cache=none -device virtio-blk-ccw,devno=fe.0.0001,drive=virtio-disk0,id=virtio-disk0,bootindex=1
```

Configure TAP Network still not able to figure out networking, looks like I need to try it on Linux attached to switch via Lan

```
qemu-system-s390x.exe  -machine s390-ccw-virtio -smp 4 -cpu max,zpci=on -serial mon:stdio -display none -m 4096 -netdev tap,id=mynet0,ifname=TAP -device virtio-net-ccw,netdev=mynet0 -drive file=z.img,if=none,id=virtio-disk0,format=raw,cache=none -device virtio-blk-ccw,devno=fe.0.0001,drive=virtio-disk0,id=virtio-disk0,bootindex=1     
```

## Qemu Fedora 33 

```
qemu-system-s390x -machine s390-ccw-virtio -cpu max,zpci=on -serial mon:stdio -display none -smp 4 -m 8G -nic user,model=virtio,hostfwd=tcp::2222-:22,hostfwd=tcp::5901-:5901   -kernel /mnt/fedora/images/kernel.img  -initrd /mnt/fedora/images/initrd.img  -drive file=disk.img,if=none,id=drive-virtio-disk0,format=raw,cache=none  -device virtio-blk-ccw,devno=fe.0.0001,drive=drive-virtio-disk0,id=virtio-disk0,bootindex=1,scsi=off  -append 'inst.text inst.stage2=http://fedora.mirror.angkasa.id/pub/fedora-secondary/releases/33/Server/s390x/os/'
```

## Other qemu-system-s390x experiments 

| OS            | Test      |  Status                                                            |
|---------------|-----------|--------------------------------------------------------------------|
| Ubuntu 18.04  | Installer | Worked without issues and Installation compeleted                  | 
| Ubuntu 18.04  | system    | Worked without noticiable issues                                   |
| Fedora 33     | Installer | Started without issues, need to work on completing it              |
| OCP 4.2,4.5   | Installer | Started without issues, need to work on completing it              |


## OpenShift on Qemu 

### reference : https://www.openshift.com/blog/installing-ocp-in-a-mainframe-z-series
Using the below command here is the results

```
qemu-system-s390x -machine s390-ccw-virtio -cpu max,zpci=on -serial mon:stdio -display none -m 16G  -netdev tap,id=mynet0,ifname=tap0 -device virtio-net-ccw,netdev=mynet0  -kernel  images/rhcos-installer-kernel-s390x  -initrd images/rhcos-installer-initramfs.s390x.img  -drive file=dasd/bootstrap-0,if=none,id=drive-virtio-disk0,format=raw,cache=none  -device virtio-blk-ccw,devno=fe.0.0001,drive=drive-virtio-disk0,id=virtio-disk0,bootindex=1,scsi=off  -append 'rd.neednet=1  coreos.inst=yes coreos.inst.install_dev=disk/by-path/ccw-0.0.0001  coreos.inst.image_url=ftp://10.244.128.5/rhcos-4.5.4-s390x-metal.s390x.raw.gz  coreos.inst.ignition_url=ftp://10.244.128.5/bootstrap.ign  ip=10.1.1.2::10.1.1.1:255.255.255.0:::none nameserver=10.244.128.5 rd.znet=ctc,0.0.0a00,0.0.0a01,protocol=bar !condev rd.dasd=0.0.0001'
```

This command do the following 
* Boot the installation 
* Mount configure the network
* download the image and the ignition files
* Extract the image 
* Mount tmpfs 
* all coreos initialization done successfully.
* reach out to ssh
* able to ssh
* still OCP services does not work not able to investigate as the machine very slow


### Network Configuration

```
apt install bridge-utils
apt install uml-utilities
ip link add name br0vm type bridge
ip addr add 10.1.1.1/24 dev br0vm
ip link set br0vm up
tunctl -t tap0
ip link set tap0 up
brctl addif br0vm tap0
```

## Trials with hercules-390

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

#### Create dasd
```
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


## Experiment with the Installer in Hercules 

| OS            | Test      |  Status                                                            |
|---------------|-----------|--------------------------------------------------------------------|
| Ubuntu 18.04  | Installer | Worked without issues and Installation compeleted                  | 
| Ubuntu 18.04  | system    | Worked without significant issues                                  |
| Fedora 33     | Installer | Started without issues, need to work on completing it              |
| RHEL 8.x      | Installer | Failed to boot ISO                                                 |
| OCP 4.2,4.5   | Installer | Failed to boot from Reader and ISO with instruction exception      |
| OCP 4.6       | Installer | failed to boot from Reader and ISO reported missing kernel.img I can not found it in the iso too |


## Installing OpenShift on Hercules 

#### This approach does not seem to work Hercules failed to boot the CoreOS ISO or any RHEL meanwhile Fedora up to 33 workes fine not sure why will try with qemu that shows more promising results

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
