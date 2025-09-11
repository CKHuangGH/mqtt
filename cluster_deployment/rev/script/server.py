import jsonpickle
from enoslib.api import generate_inventory, run_ansible
import enoslib as en
import time
from datetime import datetime, time, timedelta
from zoneinfo import ZoneInfo

en.set_config(ansible_forks=100)

# === Grid'5000 reservation settings ===
name = "mqtt-1-now-5pm-rennes-"
clusters = "paradoxe"
site = "rennes"
duration = "61:00:00"
paris = ZoneInfo("Europe/Paris")
now_paris = datetime.now(paris)
target_local = datetime.combine(now_paris.date(), time(17, 0), tzinfo=paris)
if target_local <= now_paris:
    target_local += timedelta(days=1)

today = target_local.strftime("%Y-%m-%d")
reservation_time = target_local.strftime("%Y-%m-%d %H:%M:%S")
name_job = name + clusters
prod_network = en.G5kNetworkConf(type="prod", roles=["my_network"], site=site)

# === EnOSlib: Reserve physical nodes ===
conf = (
    en.G5kConf.from_settings(job_type="allow_classic_ssh", job_name=name_job, walltime=duration,reservation=reservation_time)
    .add_network_conf(prod_network)
    .add_network(
        id="not_linked_to_any_machine", type="slash_22", roles=["my_subnet"], site=site
    )
    .add_machine(
    roles=["role0"], cluster=clusters, nodes=12, primary_network=prod_network
    )
    .add_machine(
    roles=["role1"], cluster=clusters, nodes=12, primary_network=prod_network
    )
    .finalize()
)
provider = en.G5k(conf)
roles, networks = provider.init()
roles = en.sync_info(roles, networks)
print(provider)
print(roles)
print(networks)

# === Save physical host and network info for reuse ===
with open("reserved_management.json", "w") as f:
    f.write(jsonpickle.encode(roles))

with open("reserved_management_networks.json", "w") as f:
    f.write(jsonpickle.encode(networks))
    
for i in range(10, 0, -1):
    print(f"Remaining: {i} seconds")
    time.sleep(1)

print("Reservation management: physical nodes and network configuration.")