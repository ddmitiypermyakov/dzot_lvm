#!/bin/bash


#На выделенных дисках будем экспериментировать. Диски sdb, sdc будем использовать для базовых вещей и снапшотов. На дисках sdd,sde создадим lvm mirror.
#Также можно воспользоваться утилитой lvmdiskscan:

lsblk
lvmdiskscan

#диск для будущего использования LVM - создадим PV:

pvcreate /dev/sdb

#Physical volume "/dev/sdb" successfully created

#первый уровень абстракции - VG

vgcreate ot /dev/sdb

#Volume group "ot" successfully created

#  Logical Volume (далее - LV):
lvcreate -l+80%FREE -n test ot
#Logical volume "test" created.

#информация о только что созданном Volume Group
vgdisplay ot
#######################################
#  --- Volume group ---
#  VG Name               ot
#  System ID
#  Format                lvm2
#  Metadata Areas        1
#  Metadata Sequence No  2
#  VG Access             read/write
#  VG Status             resizable
#  MAX LV                0
# Cur LV                1
# Open LV               0
# Max PV                0
# Cur PV                1
# Act PV                1
# VG Size               <10.00 GiB
# PE Size               4.00 MiB
# Total PE              2559
# Alloc PE / Size       2047 / <8.00 GiB
# Free  PE / Size       512 / 2.00 GiB
# VG UUID               r7vcbK-nyXR-D1dA-Sm0X-RDRe-c1Sl-382YEw


#посмотреть информацию о том, какие диски входит в VG:
vgdisplay -v ot | grep 'PV Name'
#PV Name               /dev/sdb


#На примере с расширением VG мы увидим, что сюда добавится еще один диск.
#Детальную информацию о LV получим командой:

lvdisplay /dev/ot/test

#В сжатом виде информацию можно получить командами vgs и lvs:
vgs
lvs

#Мы можем создать еще один LV из свободного места. На этот раз создадим не экстентами, а абсолютным значением в мегабайтах:

 lvcreate -L100M -n small ot
 #Logical volume "small" created.
 
 lvs
 
 mkfs.ext4 /dev/ot/test

mount /dev/ot/test /data/
mount | grep /data

###################
#Расширение LVM
#################

#Допустим, перед нами встала проблема нехватки свободного места в директории /data. Мы можем расширить файловую систему на LV /dev/otus/test за счет нового блочного устройства /dev/sdc.
pvcreate /dev/sdc
 vgextend ot /dev/sdc
 vgdisplay -v ot | grep 'PV Name'
 #места в VG прибавилос
 vgs
 # VG #PV #LV #SN Attr   VSize  VFree
 # ot   2   2   0 wz--n- 11.99g <3.90g
#Заполнить нулями /имитация заполнения нулями
dd if=/dev/zero of=/data/test.log bs=1M count=8000 status=progress

df -Th /data/
#Filesystem          Type  Size  Used Avail Use% Mounted on
#/dev/mapper/ot-test ext4  7.9G  7.8G     0 100% /data

lvextend -l+80%FREE /dev/ot/test
 # Size of logical volume ot/test changed from <8.00 GiB (2047 extents) to <11.12 GiB (2846 extents).
 # Logical volume ot/test successfully resized.
 
lvs /dev/ot/test
 # LV   VG Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  # test ot -wi-ao---- <11.12g
  

#файловая система при этом осталась прежнего размера:

df -Th /data
#Filesystem            Type  Size  Used Avail Use% Mounted on
#/dev/mapper/otus-test ext4  7.8G  7.8G     0 100% /data

resize2fs /dev/ot/test
df -Th /data

#Допустим Вы забыли оставить место на снапшоты. Можно уменьшить существующий LV с помощью команды lvreduce, но перед этим необходимо отмонтировать файловую систему, проверить её на ошибки и уменьшить ее размер:

umount /data

e2fsck -fy /dev/ot/test


resize2fs /dev/ot/test 10G
lvreduce /dev/ot/test -L 10G


mount /dev/ot/test /data

# ФС и lvm необходимого размера:
lvs /dev/ot/test
#  LV   VG Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
#  test ot -wi-ao---- 10.00g


###########################
#Работа со снапшотами#
#######################
#Снапшот создается командой lvcreate, только с флагом -s, который указывает на то, что это снимок
lvcreate -L 500M -s -n test-snap /dev/ot/test
#Проверка 
vgs -o +lv_size,lv_name | grep test

#Здесь ot-test-real — оригинальный LV, ot-test--snap — снапшот, а ot-test--snap-cow — copy-on-write, сюда пишутся изменения.

#Монтирование

mkdir /data-snap
mount /dev/ot/test-snap /data-snap/
ll /data-snap

#Удалим файл на оригинале

 rm /data/test.log
 ll /data

umount /data



lvconvert --merge /dev/ot/test-snap
mount /dev/otus/test /data

ll /data

#################
#####LVM-RAID
##################
pvcreate /dev/sd{d,e}
vgcreate vg0 /dev/sd{d,e}
pvs


