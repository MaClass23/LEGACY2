
/*
variable "ingressrules" {
    type = list(number)
    default = [22,80,8080,443]

}
variable "egressrules" {
    type = list(number)
    default = [22,8080,80,443]
}
*/

variable "region" {
    type = string
    default = "us-east-2"
}

variable "key_name" {
    type = string
    default = "legacykey1"
}

variable "instance_type" {
    type = string
    default = "t2.medium"
}

variable "ami" {
    type = string
    default = "ami-0b9064170e32bde34"
}
