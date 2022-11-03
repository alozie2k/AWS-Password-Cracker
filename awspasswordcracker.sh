#!/bin/bash

# script used to crack AWS passwords 


=

# in EC2 [Launch Instance]
# choose Amazon Linux GRID AMI
# choose GPU instances g2.2xlarge

# login
# ssh -i ~/src/bamx/backend/conf/aws/Bamx-Dev.pem ec2-user@54.175.107.34

# erase graphics drivers then update all the packages in the insatnce and then reboot it
sudo yum erase nvidia cuda
sudo yum update -y
sudo reboot

# install kernel dev headers needed by drivers and the Development Tools package group.
sudo yum groupinstall -y "Development tools"
sudo yum install kernel-devel-`uname -r`

# install the NVIDIA drivers and reboot the instance again
wget http://us.download.nvidia.com/XFree86/Linux-x86_64/346.35/NVIDIA-Linux-x86_64-346.35.run
sudo /bin/bash NVIDIA-Linux-x86_64-346.35.run
sudo reboot

# make sure  everything is working
nvidia-smi -q | head

# install cudaHashcat and check if it  works
wget http://hashcat.net/files/cudaHashcat-1.36.7z
wget ftp://rpmfind.net/linux/opensuse/factory/repo/oss/suse/x86_64/p7zip-9.38.1-1.1.x86_64.rpm
sudo yum install -y p7zip-9.38.1-1.1.x86_64.rpm
7z x cudaHashcat-1.36.7z
cd cudaHashcat-1.36
./cudaHashcat64.bin -b | tee benchmark-cudaHashcat-1.36-GP2-GPU.log

# add an example user
sudo adduser crackme
# set a password
echo -e 'password1234\npassword1234' | sudo passwd crackme
# extract SHA512-encrypted  password
sudo grep crackme /etc/shadow | cut -d: -f2 > crackme.hash

# download good password dictionary (~14 million entries)
wget http://downloads.skullsecurity.org/passwords/rockyou.txt.bz2
bunzip2 rockyou.txt.bz2
# use cudaHashcat + password dict to crack SHA-512 encrypted password very quickly
time ./cudaHashcat64.bin -m 1800 -w 3 -a 0 crackme.hash rockyou.txt && cat cudaHashcat.pot

<<RESULTS
[ec2-user@ip-172-31-28-132 cudaHashcat-1.36]$ time ./cudaHashcat64.bin -m 1800 -w 3 -a 0 crackme.hash rockyou.txt && cat cudaHashcat.pot
cudaHashcat v1.36 starting...
Device #1: GRID K520, 4095MB, 797Mhz, 8MCU
Hashes: 1 hashes; 1 unique digests, 1 unique salts
Bitmaps: 16 bits, 65536 entries, 0x0000ffff mask, 262144 bytes, 5/13 rotates
Rules: 1
Applicable Optimizers:
* Zero-Byte
* Single-Hash
* Single-Salt
Watchdog: Temperature abort trigger set to 90c
Watchdog: Temperature retain trigger set to 80c
Device #1: Kernel ./kernels/4318/m01800.sm_30.64.ptx
Device #1: Kernel ./kernels/4318/amp_a0_v1.64.ptx
INFO: removed 1 hash found in pot file
Session.Name...: cudaHashcat
Status.........: Cracked
Input.Mode.....: File (rockyou.txt)
Hash.Target....: $6$p45K3h8O$CCCwNLDAuicPtGX2g1LEbpshNC/nV...
Hash.Type......: sha512crypt, SHA512(Unix)
Time.Started...: 0 secs
Speed.GPU.#1...:        0 H/s
Recovered......: 1/1 (100.00%) Digests, 1/1 (100.00%) Salts
Progress.......: 0/0 (100.00%)
Rejected.......: 0/0 (100.00%)
Restore point..: 0/0 (100.00%)
HWMon.GPU.#1...: 99% Util, 41c Temp, N/A Fan
Started: Wed Jun 24 03:34:05 2015
Stopped: Wed Jun 24 03:34:05 2015
real0m0.905s
user0m0.120s
sys0m0.456s
$6$p45K3h8O$CCCwNLDAuicPtGX2g1LEbpshNC/nVneF0UaosdSTOFfLK2  OOlv5fsbG79vVYKsI3RsV3Viu.2/IU6LDXzKDPy.:password1234
RESULTS


