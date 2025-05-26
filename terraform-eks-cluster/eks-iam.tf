
data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

################################################################################
# IAM Role
################################################################################

locals {
 iam_role_policy_prefix = "arn:${data.aws_partition.current.partition}:iam::aws:policy"

  ipv4_cni_policy = { for k, v in {
    AmazonEKS_CNI_Policy = "${local.iam_role_policy_prefix}/AmazonEKS_CNI_Policy"
  } : k => v if var.iam_role_attach_cni_policy && var.cluster_ip_family == "ipv4" }
  ipv6_cni_policy = { for k, v in {
    AmazonEKS_CNI_IPv6_Policy = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/AmazonEKS_CNI_IPv6_Policy"
  } : k => v if var.iam_role_attach_cni_policy && var.cluster_ip_family == "ipv6" }

}



# IAM role for eks

resource "aws_iam_role" "cluster_role" {
  name = "eks-cluster-role"
  name_prefix = "${var.cluster_name}"
  tags = {
    tag-key = "${var.cluster_name}-eks-cluster-role"
  }

  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "eks.amazonaws.com"
                ]
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
POLICY
}

# eks policy attachment

resource "aws_iam_role_policy_attachment" "demo-AmazonEKSClusterPolicy" {
  role       = aws_iam_role.cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_iam_policy_document" "custom_policy_document"{
  statement {
    sid = 0
    actions = [ 
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ListGrants",
      "kms:DescribeKey"
     ]
     resources = [ var.kms_key_id ]
  }
  statement {
    sid = "1"

    actions = [
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation",
    ]

    resources = [
      "arn:aws:s3:::*",
    ]
  }
}
resource "aws_iam_policy" "custom_policy" {
    name = "${var.cluster_name}-custom-policy"
    description = "Eks Cluster custom policy"
    policy =  data.aws_iam_policy_document.custom_policy_document.name
}

resource "aws_iam_role_policy_attachment" "custom_policy_attachment" {
  policy_arn = aws_iam_policy.custom_policy.arn
  role = aws_iam_role.cluster_role.name
}

# role for nodegroup
resource "aws_iam_role" "nodes" {
  name = "${var.cluster_name}-eks-worker-node-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = { for k, v in merge(
    {
      AmazonEKSWorkerNodePolicy          = "${local.iam_role_policy_prefix}/AmazonEKSWorkerNodePolicy"
      AmazonEC2ContainerRegistryReadOnly = "${local.iam_role_policy_prefix}/AmazonEC2ContainerRegistryReadOnly"
    },
    local.ipv4_cni_policy,
    local.ipv6_cni_policy
  ) : k => v if local.create_iam_role }

  policy_arn = each.value
  role       = aws_iam_role.nodes.name
}


# IAM policy attachment to nodegroup

resource "aws_iam_role_policy_attachment" "nodes-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}
