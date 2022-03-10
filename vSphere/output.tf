/*
Output Variables
*/
output "vsphere_ipv4_address" {
  value = "${zipmap(
    flatten(list(
      vsphere_virtual_machine.standalone.*.name,
    )),
    flatten(list(
      vsphere_virtual_machine.standalone.*.default_ip_address,
    )),
)}"
}
