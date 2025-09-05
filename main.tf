terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpc_network" {
  name                    = "wordpress-vpc"
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_project_service" "servicenetworking" {
  project = var.project_id
  service                    = "servicenetworking.googleapis.com"
  disable_on_destroy         = false // destroy時にAPIを無効にする
}

resource "google_compute_global_address" "private_ip_alloc" {
  project = var.project_id
  provider      = google-beta
  name          = "private-ip-alloc-for-gcp-services"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  ip_version    = "IPV4"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]

  // APIとIPアドレス範囲が作成された後に、この接続が作成されるように依存関係を設定
  depends_on = [
    google_project_service.servicenetworking,
    google_compute_global_address.private_ip_alloc,
  ]
}

resource "google_compute_subnetwork" "public_subnet" {
  name          = "wordpress-public-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_firewall" "allow_http" {
  name    = "wordpress-allow-http"
  network = google_compute_network.vpc_network.name

  // このルールを適用する通信 (イングレス = 内向き)
  direction = "INGRESS"

  // 許可するプロトコルとポート
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  // どのIPアドレスからの通信を許可するか (0.0.0.0/0 は "すべてのIPアドレス")
  source_ranges = ["0.0.0.0/0"]

  // どのインスタンスにこのルールを適用するかを識別するためのタグ
  target_tags = ["wordpress-web"]
}

resource "google_compute_firewall" "allow_ssh" {
  name      = "wordpress-allow-ssh"
  network   = google_compute_network.vpc_network.name
  direction = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["wordpress-web"]
}

resource "google_compute_instance" "wordpress_vm" {
  name         = "wordpress-instance"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"

  // ファイアウォールルールを適用するためのタグ
  tags = ["wordpress-web"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.id
    // access_config {} を記述することで、パブリックIPアドレスが割り当てられる
    access_config {}
  }

  # lifecycle {
  #   prevent_destroy = true
  # }

  metadata = {
    startup-script = file("startup-script.sh")

    db_host     = google_sql_database_instance.wordpress_db_instance.private_ip_address
    db_name     = google_sql_database.wordpress_db.name
    db_user     = google_sql_user.wordpress_user.name
    db_password = var.db_password
  }

  // データベースが作成された後にVMが作成されるように依存関係を設定
  depends_on = [google_sql_user.wordpress_user]
}

resource "google_sql_database_instance" "wordpress_db_instance" {
  project = var.project_id
  name             = "wordpress-db-instance"
  database_version = "MYSQL_8_0"
  region           = var.region

  settings {
    tier = "db-n1-standard-1"

    // IP構成: プライベートIPのみを有効化
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc_network.id
    }
  }

  deletion_protection = false

  depends_on = [ google_service_networking_connection.private_vpc_connection ]
}

resource "google_sql_database" "wordpress_db" {
  project = var.project_id
  name     = "wordpress"
  instance = google_sql_database_instance.wordpress_db_instance.name
}

resource "google_sql_user" "wordpress_user" {
  project = var.project_id
  name     = "wordpress_user"
  instance = google_sql_database_instance.wordpress_db_instance.name
  password = var.db_password
}