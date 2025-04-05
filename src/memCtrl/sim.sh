#../run.sh
make verilator-memCtrl.vvp
if [ $? -eq 0 ]; then
  obj_dir/VmemCtrl_tb
fi