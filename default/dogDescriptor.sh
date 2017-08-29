#!/usr/bin/env bash

# Standard arguments passed to all tasks.
project_name=$1
project_root=$2
pipeline_input_root=$3
pipeline_output_root=$4
tile_relative_path=$5
tile_name=$6
is_cluster_job=$7

# Custom task arguments defined by task definition
app="$8/dogDescriptor"
mcrRoot=$9

# Should be a standard project argument
if [ "$(uname)" == "Darwin" ]
then
    log_path_base="/Volumes/Spare/Projects/MouseLight/LOG/pipeline"
else
    log_path_base="/groups/mousebrainmicro/mousebrainmicro/LOG/pipeline"
fi

# Compile derivatives
input_file1="$pipeline_input_root/$tile_relative_path/$tile_name-prob.0.h5"
input_file2="$pipeline_input_root/$tile_relative_path/$tile_name-prob.1.h5"

output_file="$pipeline_output_root/$tile_relative_path/$tile_name"
output_file+="-desc"
output_file1="$output_file.0.txt"
output_file2="$output_file.1.txt"

log_file_base=${tile_relative_path//\//-}
log_file_prefix="dg-"
log_file_1="${log_path_base}/${log_file_prefix}${log_file_base}.0.txt"
log_file_2="${log_path_base}/${log_file_prefix}${log_file_base}.1.txt"
err_file_1="${log_path_base}/${log_file_prefix}${log_file_base}.0.err"
err_file_2="${log_path_base}/${log_file_prefix}${log_file_base}.1.err"

LD_LIBRARY_PATH=.:${mcrRoot}/runtime/glnxa64 ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${mcrRoot}/bin/glnxa64 ;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${mcrRoot}/sys/os/glnxa64;
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${mcrRoot}/sys/opengl/lib/glnxa64;

cmd1="${app} ${input_file1} ${output_file1} \"[11 11 11]\" \"[3.405500 3.405500 3.405500]\" \"[4.049845 4.049845 4.049845]\" \"[5 1019 5 1531 5 250]\" 4"

cmd2="${app} ${input_file2} ${output_file2} \"[11 11 11]\" \"[3.405500 3.405500 3.405500]\" \"[4.049845 4.049845 4.049845]\" \"[5 1019 5 1531 5 250]\" 4"

if [ ${is_cluster_job} -eq 0 ]
then
    export LD_LIBRARY_PATH;

    eval ${cmd1} &> ${log_file_1}

    if [ $? -eq 0 ]
    then
      echo "Completed descriptor for channel 0."
    else
      echo "Failed descriptor for channel 0."
      exit $?
    fi

    eval ${cmd2} &> ${log_file_2}
    if [ $? -eq 0 ]
    then
      echo "Completed descriptor for channel 1."
      exit 0
    else
      echo "Failed descriptor for channel 1."
      exit $?
    fi
else
    ssh login1 "source /etc/profile; export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}; bsub -K -n 1 -J ml-dg-${tile_name} -oo ${log_file_1} -eo ${err_file_1} -cwd -R\"select[broadwell]\" ${cmd1}"
    if [ $? -eq 0 ]
    then
      echo "Completed descriptor for channel 0 (cluster)."
    else
      echo "Failed descriptor for channel 0 (cluster)."
      exit $?
    fi

    ssh login1 "source /etc/profile; export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}; bsub -K -n 1 -J ml-dg-${tile_name} -oo ${log_file_2} -eo ${err_file_2} -cwd -R\"select[broadwell]\" ${cmd2}"
    if [ $? -eq 0 ]
    then
      echo "Completed descriptor for channel 1 (cluster)."
      exit 0
    else
      echo "Failed descriptor for channel 1 (cluster)."
      exit $?
    fi
fi