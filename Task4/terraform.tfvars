# Параметры учебного облака для задания 4.
# Токен аутентификации передаётся отдельно через YC_TOKEN.
cloud_id                 = "b1gfqnhrv69qkn0lcaaq"
folder_id                = "b1g0k2um9gvedtlq31fv"
administrator_cidr       = "193.42.122.136/32"
administrator_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhPLZOcdK2oJz5xvvnZ2d67SF778W1CV/foNA+LERMc future-task4"

project_name        = "future-task4"
primary_zone        = "ru-central1-a"
reserve_zone        = "ru-central1-d"
system_image_family = "ubuntu-2404-lts"
system_disk_size    = 20
core_fraction       = 20

# Учебные размеры для проверки создания инфраструктуры.
# ИИ — искусственный интеллект; finance — финтех; office — головной офис.
environment_resources = {
  finance = {
    cores          = 2
    memory         = 2
    data_disk_size = 10
  }
  ai = {
    cores          = 2
    memory         = 2
    data_disk_size = 10
  }
  office = {
    cores          = 2
    memory         = 2
    data_disk_size = 10
  }
  platform = {
    cores          = 2
    memory         = 2
    data_disk_size = 10
  }
}
