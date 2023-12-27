#!/bin/sh -l
. ~/.bashrc
. ${DIR_SPS35}/descr_SPS3.5.sh
set -eu

mymail=andrea.borrelli@cmcc.it

usage() { echo "Usage: $0 [-m <machine string >] [-q <queue string>] [-s <scriptname string >] [-j <jobname string >] [-d <scriptdir string >] [-l <logdir string >] [-i <input string OPTIONAL>] [-R <cores in the same node OPTIONAL BUT REQUIRES ntask>] [-f <is this the model? OPTIONAL>] [-p <previousjob string OPTIONAL>] [-w <second previousjob string OPTIONAL>] [-Z <no arg string OPTIONAL>] [-M <memory integer OPTIONAL >] [-P <partition string OPTIONAL>] [-Q <qos string OPTIONAL>] [-r <reservation string OPTIONAL>] [-n <ntask string OPTIONAL>] [-t <duration string OPTIONAL>] [-B <starting-time string OPTIONAL (format yyyy:mm:dd:hh:mm)>]" 1>&2; exit 1; }

# Initialize arguments
# Reason: in the SPS3 version of this script, the arguments are empty string, and "test -z" command is used. This prevents the use of "set -u" option.
starttime="None"
machine="None"
queue="None"
isthemodel="None"
coreinnode="None"
scriptname="None"
jobname="None"
input="None"
logdir="None"
scriptdir="None"
prev="None"
prev2="None"
mem="None"
partition="None"
reservation="None"
qos="None"
ntask="None"
time="None"
basic="None"

while getopts ":m:M:q:Q:f:P:r:R:n:s:t:j:i:l:d:p:w:Z:B:" o; do
    case "${o}" in
        B)
            starttime=${OPTARG}
            ;;
        m)
            machine=${OPTARG}
            ;;
        q)
            queue=${OPTARG}
            ;;
        f)
            isthemodel=${OPTARG}
            ;;
        R)
            coreinnode=${OPTARG}
            ;;
        s)
            scriptname=${OPTARG}
            ;;
        j)
            jobname=${OPTARG}
            ;;
        i)
            input=${OPTARG}
            ;;
        l)
            logdir=${OPTARG}
            ;;
        d)
            scriptdir=${OPTARG}
            ;;
        p)
            prev=${OPTARG}
            ;;
        w)
            prev2=${OPTARG}
            ;;
        M)
            mem=${OPTARG}
            ;;
        P)
            partition=${OPTARG}
            ;;
        r)
            reservation=${OPTARG}
            ;;
        Q)
            qos=${OPTARG}
            ;;
        n)
            ntask=${OPTARG}
            ;;
        t)
            time=${OPTARG}
            ;;
        Z)
            basic=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

if [ "$machine" = "None" ]
then
   echo "missing machine"
   usage
fi
if [ "$basic" = "None" ]
then
   if [ "$scriptname" = "None" ]
   then
      echo "missing scriptname"
      usage
   fi
   if [ "$jobname" = "None" ]
   then
      echo "missing jobname"
      usage
   fi
   if [ "$logdir" = "None" ]
   then
      echo "missing logdir"
      usage
   fi
   if [ "$scriptdir" = "None" ]
   then
      echo "missing scriptdir"
      usage
   fi
fi
if [  "$machine" = "athena2013" ]
then
  # initalize command
  command='bsub '
  # if you require a number of cores in the same node
  if [ "$coreinnode" != "None" ]
  then
    # if you defined the required number of cores n
    if [ "$ntask" != "None" ]
    then
       command+=' -n $ntask -R "span[ptile=$coreinnode]"'
       # if  this is the model
       if [ "$isthemodel" != "None" ]
       then
          command+=' -a poe -x'
       fi
    else
       echo "-R activated but -n missing"
       usage
    fi
  fi
      
  # first of all add condition for -sla attach to service class [ SC_sp1 or SC_SERIAL_sp1]
  if [ `whoami` == $operational_user -o `whoami` == "sp2" ] #  second condition just for test purposes
  then
    # queues on athena
    #  serialq_l=serial_24h
    #  parallelq_s=poe_short

    # queue condition 
    if [ "$queue" = "None" ] # if is not defined
    then
      # the only process without $queue is bsub of $case.run -> parallel, with the exception of postrun from st_archive.sh
      if [[ "$scriptname" == *"postrun"* ]]; then
        command+=' -sla SC_SERIAL_sp1'
      # exception for ag_h process (CAM atmospheric IC condition) don't send over sla (since run 7 days before) 
      elif [[ "$scriptname" == *"ag_h"* ]]; then
      :
      fi

    else 
      # $queue is defined and contains string poe -> parallel
      if [[ "$queue" == *"poe"* ]]; then
        command+=' -sla SC_sp1'
      # $queue is defined and contains string serial -> serial        
      elif [[ "$queue" == *"serial"* ]]; then
        command+=' -sla SC_SERIAL_sp1'
      fi
    fi

  fi

   if [ "$basic" != "None" ]
   then
      command+=' < '
   else
      command+=" -rn -Ep '$DIR_SPS3/Job_report_email.sh $mymail' -q $queue -J $jobname -o $logdir/${jobname}_%J.out -e $logdir/${jobname}_%J.err"
      if [ "$prev" != "None" ]
      then
         if [ "$prev2" != "None" ]
         then
            command+=' -w "done('$prev') && done('$prev2')"'
         else
            command+=' -w "done('$prev')"'
         fi
      fi
      if [ "$mem" != "None" ]
      then
# (mem is expressed in MB)
         command+=' -R "rusage[mem='$mem']" -M $mem'
      fi
   fi

   if [ "$input" = "None" ]
   then
     input=""
   fi

   set -evx   
   command+=' '$scriptdir/$scriptname
   echo $command $input
   eval $command ${input}
   exit 0
fi

if [  "$machine" = "zeus" ]
then
  # initalize command
  command='bsub '
  # if you require a number of cores in the same node
  if [ "$coreinnode" != "None" ]
  then
    # if you defined the required number of cores n
    if [ "$ntask" != "None" ]
    then
       command+=' -n $ntask -R "span[ptile=$coreinnode]"'
       # if  this is the model
       if [ "$isthemodel" != "None" ]
       then
          command+=' -x'
       fi
    else
       echo "-R activated but -n missing"
       usage
    fi
  fi
      
  # first of all add condition for -sla attach to service class [ SC_sp1 or SC_SERIAL_sp1]
  if [ `whoami` == $operational_user -o `whoami` == "sp2" ] #  second condition just for test purposes
  then
    # queues on zeus
    #  serialq_l=s_long
    #  parallelq_s=p_short

    # queue condition 
    if [ "$queue" == "None" ] # if is not defined
    then
      # the only process without $queue is bsub of $case.run -> parallel, with the exception of postrun from st_archive.sh
      if [[ $scriptname == *"postrun"* ]]; then
        command+=' -sla ${sla_serialID} -P $pID -app $S_apprun'
      # exception for ag_h process (CAM atmospheric IC condition) don't send over sla (since run 7 days before) 
#      elif [[ $scriptname == *"ag_h"* ]]; then
#      :
      fi

    else 
      # $queue is defined and contains string poe -> parallel
      command+=' -P $pID'
      if [[ "$queue" == *"p_"* ]]; then
        command+=' -sla $slaID -app $apprun'
      # $queue is defined and contains string serial -> serial        
      elif [[ "$queue" == *"s_"* ]]; then
        if [ `whoami` == $operational_user ]
        then
           command+=' -sla ${sla_serialID} -app $S_apprun'
        fi
      fi
    fi

   fi

   if [ "$basic" != "None" ]
   then
      command+=' < '
   else
      command+=" -rn -Ep '$DIR_SPS35/Job_report_email.sh $mymail' -q $queue -J $jobname -o $logdir/${jobname}_%J.out -e $logdir/${jobname}_%J.err"
      if [ "$prev" != "None" ]
      then
         if [ "$prev2" != "None" ]
         then
            command+=' -w "done('$prev') && done('$prev2')"'
         else
            command+=' -w "done('$prev')"'
         fi
      fi
      if [ "$mem" != "None" ]
      then
# (mem is expressed in MB)
         command+=' -R "rusage[mem='$mem']" -M $mem'
      fi
   fi
   if [ "$starttime" != "None" ]
   then
     command+=' -b '"'$starttime'"''
   fi
   if [ "$time" != "None" ]
   then
     command+=' -W '"'$time:00'"''
   fi

   if [ "$input" = "None" ]
   then
     input=""
   fi

   set -evx   
   command+=' '$scriptdir/$scriptname
   echo $command $input
   eval $command ${input}
   exit 0
fi

# Marconi (Antonio-CMCC to be tested)
if [  "$machine" = "marconi" ]
then
   if [ "$basic" != "None" ]
   then
	command='sbatch '
   else
      # knl_usr_prod 
      # sbatch  --account=CMCC_Copernic_1 --partition=knl_usr_prod  --reservation=cmcc_SPS3 --job-name=SPS3_${caso}_a --out=$HOME/CESM/CESM1.2/GIT/cesm/cases/$caso/logs/SPS3_${caso}_a_stdout.%J --err=$HOME/CESM/CESM1.2/GIT/cesm/cases/$caso/logs/SPS3_${caso}_a_stderr.%J --ntask$
	command="sbatch --account=CMCC_Copernic_1 --partition=$queue --reservation=cmcc_SPS3 --job-name=$jobname --out=$logdir/${jobname}_%J.out --err=$logdir/${jobname}_%J.err  --time=02:00:00 --mail-type=ALL --mail-user=$mymail"
     	if [ "$prev" != "None" ]
      	then
        	if [ "$prev2" != "None" ]
        	then
            		command+=' -w "done('$prev') && done('$prev2')"'
         	else
            		command+=' -w "done('$prev')"'
         	fi
      	fi
     # If qos is defined, then add it serial
        if [ "$qos" != "None" ]
        then
          command+=' --qos=$qos '
        fi
      	if [ "$mem" != "None" ]
      	then
        # (mem is expressed directly)
         	command+=' --mem=$mem '
      	fi
        if [ "$ntask" != "None" ]
        then
               command+=' --ntasks=$ntask '
	else
               command+=' --ntasks=1 '
        fi

   fi
   command+=' '$scriptdir/$scriptname
   set -evx
   echo $command $input
   eval $command ${input}
   exit 0
   set +evx   
fi
