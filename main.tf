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

  // 起動時に実行するスクリプトを指定
  metadata_startup_script = file("startup-script.sh")

  // データベースが作成される前に、このインスタンスが削除されないようにする
  // (後のステップでデータベースとの依存関係を定義します)
  lifecycle {
    prevent_destroy = true
  }
}
