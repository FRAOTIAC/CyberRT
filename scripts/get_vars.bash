cyber_env=" PATH LD_LIBRARY_PATH CMAKE_PREFIX_PATH PKG_CONFIG_PATH PYTHONPATH"
env_string=""
for e in ${cyber_env}; do
    env_string+="$e=${!e};"
done
echo "$env_string"