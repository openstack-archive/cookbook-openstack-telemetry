source 'https://supermarket.chef.io'

%w(common compute identity image network).each do |cookbook|
  if Dir.exist?("../cookbook-openstack-#{cookbook}")
    cookbook "openstack-#{cookbook}", path: "../cookbook-openstack-#{cookbook}"
  else
    cookbook "openstack-#{cookbook}", git: "https://git.openstack.org/openstack/cookbook-openstack-#{cookbook}"
  end
end

cookbook 'openstackclient',
  github: 'cloudbau/cookbook-openstackclient'

metadata
