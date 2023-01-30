variable "prefix" {
  description = "Naming Prefix"
  type        = string
  default     = "acg"
}

variable "env" {
  description = "Name of Environment"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "Name of AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "app_subnets" {
  description = "Subnet CIDR blocks"
  type        = list(string)
  default     = ["192.168.212.0/26", "192.168.212.64/26"]
}

variable "data_subnets" {
  description = "Subnet CIDR blocks"
  type        = list(string)
  default     = ["192.168.212.128/26", "192.168.212.192/26"]
}

variable "dev_key" {
  description = "Dev Key Pair"
  type        = string
  default     = ""
}