resource "aws_efs_file_system" "this" {
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "elastic"

  tags = merge(var.tags, { Name = "${var.name}-efs" })
}

resource "aws_security_group" "efs" {
  name        = "${var.name}-efs"
  description = "Allow NFS from EKS nodes"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-efs" })
}

resource "aws_vpc_security_group_ingress_rule" "nfs" {
  security_group_id            = aws_security_group.efs.id
  referenced_security_group_id = var.allowed_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
  description                  = "NFS from EKS cluster security group"
}

resource "aws_efs_mount_target" "this" {
  count = length(var.subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}