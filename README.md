# System Z

Installation
```
c:\Program Files\qemu\qemu-system-s390x.exe" -machine s390-ccw-virtio -cpu max,zpci=on -serial mon:stdio -display none -m 4096 -nic user,model=virtio,hostfwd=tcp::2222-:22 --cdrom ubuntu-18.04.5-server-s390x.iso  -kernel kernel.s390 -initrd initrd.s390 -drive file=z.img,if=none,id=virtio-disk0,format=raw,cache=none -device virtio-blk-ccw,devno=fe.0.0001,drive=drive=virtio=disk0,id=virtio-disk0,bootindex=1
```

Booting

```
c:\Program Files\qemu\qemu-system-s390x.exe" -machine s390-ccw-virtio -cpu max,zpci=on -serial mon:stdio -display none -m 4096 -nic user,model=virtio,hostfwd=tcp::2222-:22  -drive file=z.img,if=none,id=virtio-disk0,format=raw,cache=none -device virtio-blk-ccw,devno=fe.0.0001,drive=drive=virtio=disk0,id=virtio-disk0,bootindex=1,scsi=off
```
