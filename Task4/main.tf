terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.225.0"
    }
  }
}

# Токен передаётся через переменную окружения YC_TOKEN.
provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
}

locals {
  # В каждой среде создаются основной и резервный узлы в разных зонах.
  nodes = {
    finance-primary  = { environment = "finance", zone = var.primary_zone, subnet = "10.10.1.0/24" }
    finance-reserve  = { environment = "finance", zone = var.reserve_zone, subnet = "10.10.2.0/24" }
    ai-primary       = { environment = "ai", zone = var.primary_zone, subnet = "10.20.1.0/24" }
    ai-reserve       = { environment = "ai", zone = var.reserve_zone, subnet = "10.20.2.0/24" }
    office-primary   = { environment = "office", zone = var.primary_zone, subnet = "10.30.1.0/24" }
    office-reserve   = { environment = "office", zone = var.reserve_zone, subnet = "10.30.2.0/24" }
    platform-primary = { environment = "platform", zone = var.primary_zone, subnet = "10.40.1.0/24" }
    platform-reserve = { environment = "platform", zone = var.reserve_zone, subnet = "10.40.2.0/24" }
  }
}

data "yandex_compute_image" "system" {
  family = var.system_image_family
}

resource "yandex_vpc_network" "project" {
  name = "${var.project_name}-network"
}

resource "yandex_vpc_subnet" "node" {
  for_each = local.nodes

  name           = "${var.project_name}-${each.key}-subnet"
  zone           = each.value.zone
  network_id     = yandex_vpc_network.project.id
  v4_cidr_blocks = [each.value.subnet]
}

resource "yandex_vpc_security_group" "environment" {
  for_each = var.environment_resources

  name       = "${var.project_name}-${each.key}-access"
  network_id = yandex_vpc_network.project.id

  ingress {
    description    = "Подключение администратора по SSH"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = [var.administrator_cidr]
  }

  ingress {
    description = "Обмен основного и резервного узлов своей среды"
    protocol    = "ANY"
    v4_cidr_blocks = [
      for node in values(local.nodes) : node.subnet
      if node.environment == each.key
    ]
  }

  # Платформа получает опубликованные наборы через интерфейсы направлений.
  dynamic "ingress" {
    for_each = each.key == "platform" ? [] : [1]
    content {
      description = "Получение данных платформой по HTTPS"
      protocol    = "TCP"
      port        = 443
      v4_cidr_blocks = [
        local.nodes["platform-primary"].subnet,
        local.nodes["platform-reserve"].subnet
      ]
    }
  }

  egress {
    description    = "Исходящие подключения и загрузка пакетов"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_compute_disk" "system" {
  for_each = local.nodes

  name     = "${var.project_name}-${each.key}-system"
  zone     = each.value.zone
  type     = "network-hdd"
  size     = var.system_disk_size
  image_id = data.yandex_compute_image.system.id

  # Обновление семейства образов не должно заменять уже созданный диск.
  lifecycle {
    ignore_changes = [image_id]
  }
}

resource "yandex_compute_disk" "data" {
  for_each = local.nodes

  name = "${var.project_name}-${each.key}-data"
  zone = each.value.zone
  type = "network-hdd"
  size = var.environment_resources[each.value.environment].data_disk_size
}

resource "yandex_compute_instance" "node" {
  for_each = local.nodes

  name        = "${var.project_name}-${each.key}"
  zone        = each.value.zone
  platform_id = "standard-v3"

  resources {
    cores         = var.environment_resources[each.value.environment].cores
    memory        = var.environment_resources[each.value.environment].memory
    core_fraction = var.core_fraction
  }

  boot_disk {
    disk_id = yandex_compute_disk.system[each.key].id
  }

  secondary_disk {
    disk_id     = yandex_compute_disk.data[each.key].id
    device_name = "data"
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.node[each.key].id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.environment[each.value.environment].id]
  }

  # SSH — защищённое подключение к серверу. Здесь только открытый ключ.
  metadata = {
    ssh-keys = "ubuntu:${trimspace(var.administrator_public_key)}"
  }

  labels = {
    project     = var.project_name
    environment = each.value.environment
  }
}
