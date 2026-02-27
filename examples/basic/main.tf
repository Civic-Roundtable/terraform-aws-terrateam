provider "aws" {
  region = "us-east-1"
}

module "terrateam" {
  source = "../../"

  vpc_id             = "vpc-0123456789abcdef0"
  public_subnet_ids  = ["subnet-aaa", "subnet-bbb"]
  private_subnet_ids = ["subnet-ccc", "subnet-ddd"]
  domain             = "terrateam.example.com"

  # Uncomment to enable HTTPS:
  # acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxxxxx"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
