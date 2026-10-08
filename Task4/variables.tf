variable "cloud_id" {
  description = "Идентификатор учебного облака Yandex Cloud."
  type        = string

  validation {
    condition     = length(trimspace(var.cloud_id)) > 0
    error_message = "Укажите cloud_id учебного облака в terraform.tfvars."
  }
}

variable "folder_id" {
  description = "Идентификатор каталога, в котором создаются ресурсы задания."
  type        = string

  validation {
    condition     = length(trimspace(var.folder_id)) > 0
    error_message = "Укажите folder_id учебного каталога в terraform.tfvars."
  }
}

variable "project_name" {
  description = "Общий префикс имён ресурсов задания."
  type        = string
  default     = "future-task4"
}

variable "primary_zone" {
  description = "Зона доступности основных узлов."
  type        = string
  default     = "ru-central1-a"
}

variable "reserve_zone" {
  description = "Зона доступности резервных узлов."
  type        = string
  default     = "ru-central1-d"

  validation {
    condition     = var.reserve_zone != var.primary_zone
    error_message = "Основные и резервные узлы должны находиться в разных зонах."
  }
}

variable "system_image_family" {
  description = "Семейство образа операционной системы."
  type        = string
  default     = "ubuntu-2404-lts"
}

variable "administrator_cidr" {
  description = "Публичный IPv4-адрес администратора с маской /32 для доступа по SSH."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.administrator_cidr)) && endswith(var.administrator_cidr, "/32")
    error_message = "Укажите IPv4-адрес администратора с маской /32."
  }
}

variable "administrator_public_key" {
  description = "Открытый ключ администратора для SSH. Закрытый ключ остаётся на компьютере."
  type        = string

  validation {
    condition     = can(regex("^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp256) [A-Za-z0-9+/=]+", trimspace(var.administrator_public_key)))
    error_message = "Укажите открытый ключ SSH в administrator_public_key."
  }
}

variable "system_disk_size" {
  description = "Размер системного диска каждого узла в гигабайтах."
  type        = number
  default     = 20

  validation {
    condition     = var.system_disk_size >= 20
    error_message = "Для системного диска укажите не менее 20 ГБ."
  }
}

variable "core_fraction" {
  description = "Гарантированная доля производительности ядра в процентах."
  type        = number
  default     = 20

  validation {
    condition     = contains([20, 50, 100], var.core_fraction)
    error_message = "Допустимые значения core_fraction: 20, 50 или 100."
  }
}

variable "environment_resources" {
  description = "Ресурсы одного узла каждой среды. Резервный узел получает те же параметры."
  type = map(object({
    cores          = number
    memory         = number
    data_disk_size = number
  }))

  validation {
    condition     = toset(keys(var.environment_resources)) == toset(["finance", "ai", "office", "platform"])
    error_message = "Опишите четыре среды: finance, ai, office и platform."
  }

  validation {
    condition = alltrue([
      for resources in values(var.environment_resources) :
      resources.cores >= 2 && resources.cores % 2 == 0 &&
      resources.memory >= resources.cores && resources.data_disk_size >= 10
    ])
    error_message = "Нужны чётное число ядер от 2, не менее 1 ГБ памяти на ядро и диск данных от 10 ГБ."
  }
}
