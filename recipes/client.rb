#
# Cookbook Name:: ossec
# Recipe:: client
#
# Copyright 2010, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

ossec_server = Array.new

if node.run_list.roles.include?(node['ossec']['server_role'])
  ossec_server << node['ipaddress']
else
  search(:node,"role:#{node['ossec']['server_role']}") do |n|
    ossec_server << n['ipaddress']
  end
end

node.set['ossec']['user']['install_type'] = "agent"
node.set['ossec']['user']['agent_server_ip'] = ossec_server.first

node.save

include_recipe "ossec"

#
# register with server
#
# ossec-authd doesn't include any type of client authentication, and the docs recommend only
# starting it when adding new clients. That sounds tedious. Instead we will use ssh as the authentication
# layer and only allow access from localhost.
#
# FIXME how do we add a firewall rule for this in a sane way?
#
bash "register with ossec server" do
  user "root"
  cwd  "/var/ossec"
  code <<-EOH
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -N -T -L1515:127.0.0.1:1515 -i .ssh/id_rsa ossecd@#{node['ossec']['user']['agent_server_ip']} &
    sleep 1
    bin/agent-auth -m 127.0.0.1 && pkill -f -- '-L1515:127.0.0.1:1515'
  EOH

  not_if { File.exists? "/var/ossec/etc/client.keys" }
end

include_recipe "ossec::service"
