if [[ -n "${TZ}" ]]; then
  echo "Setting timezone to ${TZ}"
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
fi

cd /chia-blockchain

. ./activate

chia init

if [[ ${keys} == "generate" ]]; then
  echo "to use your own keys pass them as a text file -v /path/to/keyfile:/path/in/container and -e keys=\"/path/in/container\""
  chia keys generate
elif [[ ${keys} == "copy" ]]; then
  if [[ -z ${ca} ]]; then
    echo "A path to a copy of the farmer peer's ssl/ca required."
	exit
  else
  chia init -c ${ca}
  fi
else
  chia keys add -f ${keys}
fi

if [[ ! "$(ls -A $p)" ]]; then
    echo "Plots directory '${p}' appears to be empty, try mounting a plot directory with the docker -v command"
    exit
fi

sed -i 's/localhost/127.0.0.1/g' ~/.chia/mainnet/config/config.yaml
# use DEBUG as default log_level
sed -i 's/log_level: WARNING/log_level: DEBUG/g' /root/.chia/mainnet/config/config.yaml

if [[ ${farmer} == 'true' ]]; then
  chia start farmer-only
elif [[ ${harvester} == 'true' ]]; then
  if [[ -z ${farmer_address} || -z ${farmer_port} || -z ${ca} ]]; then
    echo "A farmer peer address, port, and ca path are required."
    exit
  else
    chia configure --set-farmer-peer ${farmer_address}:${farmer_port}
    chia start harvester
  fi
else
  chia start farmer
fi

if [[ ${testnet} == "true" ]]; then
  if [[ -z $full_node_port || $full_node_port == "null" ]]; then
    chia configure --set-fullnode-port 58444
  else
    chia configure --set-fullnode-port ${var.full_node_port}
  fi
fi

# original cmd, without recursive search for plots. chia plots add -d ${plots_dir}
find ${plots_dir} -iname "*.plot" -type f | xargs -n 1 -I[] dirname [] | grep -v "Trash" | sort --unique | xargs -n 1 -I[] chia plots add -d []

while true; do sleep 30; done;
