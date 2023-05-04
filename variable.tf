variable "region_name" {
type=string
default= "ap-south-1"
}
variable "server_port" {
type= number
default=80
}
variable "publiccidr" {
type = list(string)
default = ["0.0.0.0/0"]
}
