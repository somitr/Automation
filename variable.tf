# Active Directory & Domain Controller
variable "active_directory_domain" {
  description = "The name of the Active Directory domain, for example `consoto.local`"
  default = "somitrAzureLAB"
}
  variable "active_directory_netbios_name" {
    description = "Domain NetBios name "
    default = "somitrAzureLAB"
  }

variable "domainAdminUsername" {
    description = "The local administrator account on the Domain"
    default = "admin@somitrAzureLAB.com"
}

variable "admin_password" {
  description = "The password associated with the local administrator account on the virtual machine"
  default = "password"
}