
resource "aws_security_group" "cluster_security_group" {
  name_prefix = "${var.cluster_name}-eks-cluster-sg"
  vpc_id      = var.vpc_id
  tags = {
    Name = "${var.cluster_name}-eks-clluster-sg"
  }
}

resource "aws_security_group_rule" "cluster_ingress_rule" {
type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  security_group_id = aws_security_group.cluster_security_group.id
  source_security_group_id = aws_security_group.all_worker_mgmt.id
}

resource "aws_security_group_rule" "cluster_ingress_rule_for_vpc" {
 type = "ingress"
 from_port =  0
 to_port = 0
 protocol = "all"
 cidr_blocks = [var.vpc_cidr_block]
 security_group_id = aws_security_group.cluster_security_group.id
}

resource "aws_security_group_rule" "cluster_egress_rule" {
  description       = "allow outbound traffic to anywhere"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.cluster_security_group.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = var.vpc_id
  tags = {
    "Name" = "${var.cluster_name}-worker-node-sg"
    "karpenter.io/cluster/${var.cluster_name}" = "owned" 
    "karpenter.sh/discovery" = var.cluster_name
  }
}

resource "aws_security_group_rule" "all_worker_mgmt_ingress" {
  description       = "allow inbound traffic from eks"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  security_group_id = aws_security_group.all_worker_mgmt.id
  type              = "ingress"
  cidr_blocks = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16",
  ]
}

resource "aws_security_group_rule" "all_worker_mgmt_egress" {
  description       = "allow outbound traffic to anywhere"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.all_worker_mgmt.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}