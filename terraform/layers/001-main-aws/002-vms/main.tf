resource "aws_key_pair" "pub_key" {
  key_name   = "pub-key"
  public_key = file("../../../../id_rsa.pub")
}

###########
# Bastion #
###########

resource "aws_instance" "k3s_bastion" {
  ami                         = data.aws_ami.debian.id
  instance_type               = var.instance_type
  subnet_id                   = element(data.terraform_remote_state.vpc.outputs.public_subnet_ids, 0)
  associate_public_ip_address = true
  key_name                    = aws_key_pair.pub_key.id

  vpc_security_group_ids = [
    "${aws_security_group.sg_bastion.id}"
  ]

  tags = {
    Name = "k3s-bastion"
  }
}

resource "aws_security_group" "sg_bastion" {
  name_prefix = "${var.group}-${var.env}-${var.region}-sg-bastion"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name = "sg-bastion"
  }
}

resource "aws_security_group_rule" "ingress_ssh_bastion" {
  security_group_id = aws_security_group.sg_bastion.id

  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  type        = "ingress"
}

resource "aws_security_group_rule" "egress_all_bastion" {
  security_group_id = aws_security_group.sg_bastion.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  type        = "egress"
}

##############
# k3s master #
##############

resource "aws_instance" "k3s_masters" {
  count                       = 3
  ami                         = data.aws_ami.debian.id
  instance_type               = var.instance_type_master
  subnet_id                   = element(data.terraform_remote_state.vpc.outputs.public_subnet_ids, 0)
  associate_public_ip_address = true
  key_name                    = aws_key_pair.pub_key.id

  vpc_security_group_ids = [
    "${aws_security_group.sg_k3s_masters.id}"
  ]

  tags = {
    Name = "k3s-masters"
  }
}

resource "aws_security_group" "sg_k3s_masters" {
  name_prefix = "${var.group}-${var.env}-${var.region}-sg-k3s-masters"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name = "sg-k3s-masters"
  }
}

resource "aws_security_group_rule" "ingress_http_k3s_masters" {
  security_group_id = aws_security_group.sg_k3s_masters.id

  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  type        = "ingress"
}

resource "aws_security_group_rule" "ingress_https_k3s_masters" {
  security_group_id = aws_security_group.sg_k3s_masters.id

  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  type        = "ingress"
}

resource "aws_security_group_rule" "ingress_6443_k3s_masters" {
  security_group_id = aws_security_group.sg_k3s_masters.id

  from_port   = 6443
  to_port     = 6443
  protocol    = "tcp"
  cidr_blocks = ["${var.vpc_cidr}"]
  type        = "ingress"
}

resource "aws_security_group_rule" "ingress_ssh_bastion_k3s_masters" {
  security_group_id = aws_security_group.sg_k3s_masters.id

  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.sg_bastion.id
  type                     = "ingress"
}

resource "aws_security_group_rule" "ingress_vpc_k3s_masters" {
  security_group_id = aws_security_group.sg_k3s_masters.id

  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = ["${var.vpc_cidr}"]
  type                     = "ingress"
}

resource "aws_security_group_rule" "egress_all_k3s_masters" {
  security_group_id = aws_security_group.sg_k3s_masters.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  type        = "egress"
}

#############
# k3s nodes #
#############

resource "aws_instance" "k3s_nodes" {
  count = 3

  ami                         = data.aws_ami.debian.id
  instance_type               = var.instance_type
  subnet_id                   = element(data.terraform_remote_state.vpc.outputs.private_subnet_ids, count.index)
  associate_public_ip_address = false
  key_name                    = aws_key_pair.pub_key.id

  vpc_security_group_ids = [
    "${aws_security_group.sg_k3s_nodes.id}"
  ]

  tags = {
    Name = "k3s-nodes-${count.index}"
  }
}

resource "aws_security_group" "sg_k3s_nodes" {
  name_prefix = "${var.group}-${var.env}-${var.region}-sg-k3s-nodes"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name = "sg-k3s-nodes"
  }
}

resource "aws_security_group_rule" "ingress_6443" {
  security_group_id = aws_security_group.sg_k3s_nodes.id

  from_port   = 6443
  to_port     = 6443
  protocol    = "tcp"
  cidr_blocks = ["${var.vpc_cidr}"]
  type        = "ingress"
}

resource "aws_security_group_rule" "ingress_ssh_bastion_k3s_nodes" {
  security_group_id = aws_security_group.sg_k3s_nodes.id

  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.sg_bastion.id
  type                     = "ingress"
}

resource "aws_security_group_rule" "ingress_vpc_k3s_nodes" {
  security_group_id = aws_security_group.sg_k3s_nodes.id

  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  cidr_blocks              = ["${var.vpc_cidr}"]
  type                     = "ingress"
}

resource "aws_security_group_rule" "egress_all_k3s_nodes" {
  security_group_id = aws_security_group.sg_k3s_nodes.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  type        = "egress"
}