#../run.sh
make vlog_sim.vvp
if [ $? -eq 0 ]; then
  sim/vlog_sim.vvp
fi