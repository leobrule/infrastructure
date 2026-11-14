terraform {
  backend "gcs" {
    bucket = "mysqlproject-501213-tfstate"
    prefix = "envs/dev"
  }
}
