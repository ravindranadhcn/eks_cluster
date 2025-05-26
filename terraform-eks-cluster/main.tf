
resource "aws_eks_cluster" "this" {
  name = var.cluster_name
  role_arn = ""
  enabled_cluster_log_types = var.enabled_cluster_log_types
  version = var.eks_cluster_version
  vpc_config {
    subnet_ids = var.private_subnet_ids
    security_group_ids = [aws_security_group.cluster_security_group.id]
    endpoint_private_access = true
    endpoint_public_access = false
  }
  encryption_config {
    provider {
      key_arn = var.kms_key_id
    }
    resources = [ "secrets" ]
  }

  access_config {
    authentication_mode =    "API" 
    bootstrap_cluster_creator_admin_permissions = false
    

  }

}


resource "aws_eks_node_group" "main" {
for_each =   var.managed_groups
   cluster_name = aws_eks_cluster.this.name
   node_group_name = each.value.name
   subnet_ids = var.private_subnet_ids
   node_role_arn = aws_iam_role.nodes.name
   labels = {
     "karpenter.sh/controller" = "true"
   }
   scaling_config {
     min_size = each.value.min_size
     desired_size = each.value.desired_size
     max_size = each.value.max_size
   }
launch_template {
  id = aws_launch_template.this.id
  version = "$Latest"
}
}

resource "aws_launch_template" "this" {
  name = "${var.cluster_name}-eks-node-group-lt"
  description = "Eks Node Group Launch Template"
  vpc_security_group_ids = [aws_security_group.all_worker_mgmt.id]
  tag_specifications {
    resource_type = "instance"
    tags = {
      "Name" = "${var.cluster_name}-eks-node-group"
    }
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags = "enabled"
  }
  image_id = var.image_id
  key_name = var.key_pair_name
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 50
      volume_type = gp3
      delete_on_termination = true
      encrypted = true
    }
  }
  tags = {
    "Name" = "${var.cluster_name}-eks-node"
    "kubernates.io/cluster/${var.cluster_name}" = "owned"
  }
  user_data = base64decode(<<-EOF
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="
--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash
/etc/eks/bootstrap.sh ${var.cluster_name}
--==MYBOUNDARY==--\
  EOF
  )
}

