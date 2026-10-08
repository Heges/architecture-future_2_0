output "network_id" {
  description = "Идентификатор сети проекта."
  value       = yandex_vpc_network.project.id
}

output "subnet_ids" {
  description = "Идентификаторы подсетей основных и резервных узлов."
  value       = { for name, subnet in yandex_vpc_subnet.node : name => subnet.id }
}

output "security_group_ids" {
  description = "Группы доступа четырёх сред."
  value       = { for name, group in yandex_vpc_security_group.environment : name => group.id }
}

output "nodes" {
  description = "Созданные машины, их адреса и подключённые диски."
  value = {
    for name, node in yandex_compute_instance.node : name => {
      instance_id    = node.id
      zone           = node.zone
      private_ip     = node.network_interface[0].ip_address
      public_ip      = node.network_interface[0].nat_ip_address
      system_disk_id = yandex_compute_disk.system[name].id
      data_disk_id   = yandex_compute_disk.data[name].id
    }
  }
}
