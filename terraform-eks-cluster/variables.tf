variable "vpc_id" {
     type = string
     description = "vpc id"
     default = ""
}

variable "vpc_cidr_block" {
  
}
variable "private_subnet_ids" {
    type = list(string)
    default = [ "value" ]
}

variable "kms_key_id" {
  
}
variable "cluster_name" {
     type = string
     description = "Cluster Name"
     default = ""
}
variable "eks_cluster_version" {
  
}
variable "enabled_cluster_log_types" {
  
}

variable "managed_groups" {
  description = "Node Group details"
  type = map(object({
     name: string
     desired_size : number
     min_size : number
     max_size : number
     instance_types: list(string)
  }))
  default ={
     key1 = {
          name = "test-gp"
          desired_size = 1
          min_size = 1
          max_size = 2
          instance_types = ["t2.xlarge"]
     }
  }
}


variable "image_id" {
  
}
variable "key_pair_name" {
  
}
variable "cluster_ip_family" {
  default = "ipv4"
}


variable "create_iam_role" {
  description = "Determines whether an IAM role is created or to use an existing IAM role"
  type        = bool
  default     = true
}