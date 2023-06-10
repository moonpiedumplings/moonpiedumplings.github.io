while true ; do
   echo -n 'KSM state: '
   cat /sys/kernel/mm/ksm/run
   echo -n 'Saved (deduped) memory (bytes) : '
   echo `cat /sys/kernel/mm/ksm/pages_sharing`*4096 | bc | numfmt --to=si
   echo -n 'Actual size in memory (bytes)  : '
   echo `cat /sys/kernel/mm/ksm/pages_shared`*4096 | bc | numfmt --to=si
   egrep '(Dirty|MemFree|^Cached)' /proc/meminfo
   sleep 1
   clear
done

https://people.redhat.com/rfreire/kvm-overcommit/

rfreire@redhat.com
QEmu-kvm mM Bonus: Monitoring ksm How to Overcommit RAM while true ; do echo -n 'KSM state: ' cat /sys/kernel/mm/ksm/run echo -n 'Saved (deduped) memory (bytes) : ' echo `cat /sys/kernel/mm/ksm/pages_sharing`*4096 | bc | numfmt --to=si echo -n 'Actual size in memory (bytes) : ' echo `cat /sys/kernel/mm/ksm/pages_shared`*4096 | bc | numfmt --to=si egrep '(Dirty|MemFree|^Cached)' /proc/meminfo sleep 1 clear done
