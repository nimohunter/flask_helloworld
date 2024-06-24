resource "aws_eks_cluster" "example" {
  name     = "example-eks-cluster"
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    subnet_ids = aws_subnet.example[*].id
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks,
    aws_iam_role_policy_attachment.eks_cni,
  ]
}

resource "aws_iam_role" "eks" {
  name = "example-eks-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks" {
  role       = aws_iam_role.eks.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  role       = aws_iam_role.eks.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}