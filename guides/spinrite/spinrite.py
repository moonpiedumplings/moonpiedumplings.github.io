import subprocess

disklist = subprocess.check_output("lsblk --exclude 7 -dno NAME", shell=True, text=True).splitlines()

print(disklist)

print("\n")

cpunum =  subprocess.check_output("grep -c processor /proc/cpuinfo", shell=True, text=True).replace('\n', '')

sockets = subprocess.check_output("grep \"physical id\" /proc/cpuinfo | sort -u | wc -l", shell=True, text=True).replace('\n', '')

threadspercpu = subprocess.check_output("lscpu | grep \"Thread(s) per core\" | awk '{print $4}'", shell=True, text=True).replace('\n', '')

memory = subprocess.check_output("free -g | awk '/Mem:/ {print $2}'", shell=True, text=True).replace('\n', '')


cmd = f"qemu-system-x86_64 -cpu host -enable-kvm -smp cpus={cpunum},sockets={sockets},threads={threadspercpu} -m {int(memory) - 1}G"


cmd = cmd + " -drive file=spinrite.img,format=raw"

for disk in disklist:
    cmd = cmd + f" -drive file=/dev/{ disk },format=raw,cache=none,if=virtio "


cmd = "xinit /usr/bin/" + cmd + " -- :0 vt$XDG_VTNR"

print(cmd)

subprocess.Popen(cmd, shell=True)