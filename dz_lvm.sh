#!/bin/bash

############################
##Уменьшить том под / до 8G

##########################
echo "Уменьшить том под / до 8G"

lsblk

 pvcreate /dev/sdb
vgcreate vg_root /dev/sdb
lvcreate -n lv_root -l +100%FREE /dev/vg_root


#Создадим на нем файловую систему и смонтируем его, чтобы перенести туда данные:

mkfs.xfs /dev/vg_root/lv_root
mount /dev/vg_root/lv_root /mnt
 
yum install xfsdump -y

#копируем все данные с / раздела в /mnt:
xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt

#xfsrestore: restore complete: 34 seconds elapsed
#xfsrestore: Restore Status: SUCCESS

ls /mnt
#сконфигурируем grub для того, чтобы при старте перейти в новый /.
#Сымитируем текущий root, сделаем в него chroot и обновим grub:

for i in /proc/ /sys/ /dev/ /run/ /boot/; \
do mount --bind $i /mnt/$i; done


chroot /mnt #&& grub2-mkconfig -o /boot/grub2/grub.cfg && cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; > s/.img//g"` --force; done && /sbin/dracut -v initramfs-3.10.0-1160.102.1.el7.x86_64.img 3.10.0-1160.102.1.el7.x86_64 --force

grub2-mkconfig -o /boot/grub2/grub.cfg

#Обновим образ initrd.

cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; > s/.img//g"` --force; done
dracut -v

#/sbin/dracut -v initramfs-3.10.0-1160.102.1.el7.x86_64.img 3.10.0-1160.102.1.el7.x86_64 --force

#для того, чтобы при загрузке был смонтирован нужны root нужно в файле /boot/grub2/grub.cfg 
# заменить rd.lvm.lv=VolGroup00/LogVol00 на rd.lvm.lv=vg_root/lv_root
# В rHel8.10 (linux oracle 8.10)  требуетя править также в файле  /boot/grub2/grubenv:
# kernelopts=root=/dev/mapper/ol-root ro crashkernel=auto resume=/dev/mapper/ol-swap rd.lvm.lv=ol/root rd.lvm.lv=ol/swap rhgb quiet

sed -i 's%VolGroup00/LogVol00%vg_root/lv_root%g' /boot/grub2/grub.cfg
#sed -i 's%/dev/mapper/VolGroup00-LogVol00%/dev/vg_root/lv_root%g' /etc/fstab

lsblk
echo "Config change"
#reboot

#echo "reload Centos"
#lsblk
#lvremove /dev/VolGroup00/LogVol00



sed -i 's%vg_root/lv_root%VolGroup00/LogVol00%g' /boot/grub2/grub.cfg
#удаляем старый LV размером в 40G и создаём новый на 8G
lvremove /dev/VolGroup00/LogVol00

lvcreate -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00

mkfs.xfs /dev/VolGroup00/LogVol00

mount /dev/VolGroup00/LogVol00 /mnt

xfsdump -J - /dev/vg_root/lv_root |  xfsrestore -J - /mnt
#xfsrestore: restore complete: 7 seconds elapsed
#xfsrestore: Restore Status: SUCCESS

#cконфигурируем grub, за исключением правки /etc/grub2/grub.cfg

 for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done

 chroot /mnt/
grub2-mkconfig -o /boot/grub2/grub.cfg

#Generating grub configuration file ...
#Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
#Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
#done

cd /boot ; for i in `ls initramfs-*img`; \
 do dracut -v $i `echo $i|sed "s/initramfs-//g; \
> s/.img//g"` --force; done


##############################################
##########Выделить том под /var в зеркало
#############################################


pvcreate /dev/sdc /dev/sdd

vgcreate vg_var /dev/sdc /dev/sdd

lvcreate -L 950M -m1 -n lv_var vg_var
 mkfs.ext4 /dev/vg_var/lv_var
#ФС

mkfs.ext4 /dev/vg_var/lv_var
mount /dev/vg_var/lv_var /mnt

cp -aR /var/* /mnt/
mkdir /tmp/oldvar && mv /var/* /tmp/oldvar
umount /mnt
mount /dev/vg_var/lv_var /var
#Правим fstab для автоматического монтирования /var:

echo "`blkid | grep var: | awk '{print $2}'` \
 /var ext4 defaults 0 0" >> /etc/fstab

reboot

#удаляем временную Volume Group:

lvremove /dev/vg_root/lv_root
vgremove /dev/vg_root
 pvremove /dev/sdb

