#
# Cookbook Name:: ossec
# Recipe:: server
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

node.set['ossec']['user']['install_type'] = "server"
node.set['ossec']['server']['maxagents']  = 1024

node.save

include_recipe "ossec"

ossec_key = data_bag_item("ossec", "ssh")

#
# set up authorized_keys so that clients can ssh in to talk to ossec-authd
#
template "#{node['ossec']['user']['dir']}/.ssh/authorized_keys" do
  source "authorized_keys.erb"
  owner "root"
  group "ossec"
  mode 0640
  variables(:key => ossec_key['pubkey'])
end

#
# Create SSL key and cert for ossec-authd
#
execute "openssl genrsa -out /var/ossec/etc/sslmanager.key 2048" do
  not_if { File.exists? "/var/ossec/etc/sslmanager.key" }
end

execute "openssl req -new -x509 -key /var/ossec/etc/sslmanager.key -out /var/ossec/etc/sslmanager.cert -days 3650 -subj /C=US/ST=CA/L=LA/O=ossec/CN=www.example.com" do
  not_if { File.exists? "/var/ossec/etc/sslmanager.cert" }
end

#
# Add an init.d script for ossec-authd
#
template "/etc/init.d/ossec-authd" do
  source "ossec-authd-init.erb"
  owner "root"
  mode 0700
end

include_recipe "ossec::service"
