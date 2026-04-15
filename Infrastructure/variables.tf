variable "rg_name" {
    type = string
}

variable "location" {
    type = string
}

variable "api_image" {
    type = string
}

variable "web_image" {
    type = string
  
}

variable "db_password" {
    type = string
    sensitive = true
}