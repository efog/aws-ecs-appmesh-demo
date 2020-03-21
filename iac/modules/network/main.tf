resource "aws_vpc" "base_vpc" {
  cidr_block = "10.0.0.0/16"
  tags       = var.tags
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id            = aws_vpc.base_vpc.id
  availability_zone = "us-west-1c"
  cidr_block        = "10.0.0.0/28"
  tags              = var.tags
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id            = aws_vpc.base_vpc.id
  availability_zone = "us-west-1b"
  cidr_block        = "10.0.0.16/28"
  tags              = var.tags
}


resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.base_vpc.id
  availability_zone = "us-west-1c"
  cidr_block        = "10.0.0.32/27"
  tags              = var.tags
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.base_vpc.id
  availability_zone = "us-west-1b"
  cidr_block        = "10.0.0.64/27"
  tags              = var.tags
}

resource "aws_internet_gateway" "network_internet_gateway" {
  vpc_id = aws_vpc.base_vpc.id
  tags   = var.tags
}

resource "aws_nat_gateway" "nat_gateway" {
  subnet_id     = aws_subnet.public_subnet_a.id
  tags          = var.tags
  allocation_id = aws_eip.nat_gateway_eip.id
}

resource "aws_eip" "nat_gateway_eip" {}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.base_vpc.id
  tags   = var.tags
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.base_vpc.id
  tags   = var.tags
}

resource "aws_route_table_association" "public_route_table_association_a" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.public_subnet_a.id
}

resource "aws_route_table_association" "public_route_table_association_b" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.public_subnet_b.id
}

resource "aws_route_table_association" "private_route_table_association_a" {
  route_table_id = aws_route_table.private_route_table.id
  subnet_id      = aws_subnet.private_subnet_a.id
}

resource "aws_route_table_association" "private_route_table_association_b" {
  route_table_id = aws_route_table.private_route_table.id
  subnet_id      = aws_subnet.private_subnet_b.id
}

resource "aws_route" "public_igw_route" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.network_internet_gateway.id
  route_table_id         = aws_route_table.public_route_table.id
}

resource "aws_route" "public_natgw_route" {
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
  route_table_id         = aws_route_table.private_route_table.id
}

resource "aws_security_group" "alb_security_group" {
  vpc_id = aws_vpc.base_vpc.id
  name   = "alb_security_group"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "bastion_security_group" {
  vpc_id = aws_vpc.base_vpc.id
  name   = "bastion_security_group"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web_security_group" {
  vpc_id = aws_vpc.base_vpc.id
  name   = "web_security_group"

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${aws_security_group.alb_security_group.id}"]
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${aws_security_group.bastion_security_group.id}"]
  }

  egress {
    to_port     = 0
    from_port   = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "application_load_balancer" {
  name               = "web-alb"
  tags               = var.tags
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.alb_security_group.id}"]
  subnets            = ["${aws_subnet.public_subnet_a.id}", "${aws_subnet.public_subnet_b.id}"]
}

resource "aws_lb_target_group" "web_app_tg" {
  name        = "web-app-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.base_vpc.id
  target_type = "ip"
  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = 80
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200-399"
  }
}

resource "aws_lb_target_group" "web_api_tg" {
  name        = "web-api-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.base_vpc.id
  target_type = "ip"
  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = 80
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200-399"
  }
}

resource "aws_alb_listener_rule" "web_app_listener_rule" {
  listener_arn = aws_lb_listener.alb_listener.arn
  priority     = 110
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_app_tg.arn
  }
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

resource "aws_alb_listener_rule" "web_api_listener_rule" {
  listener_arn = aws_lb_listener.alb_listener.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_api_tg.arn
  }
  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_app_tg.arn
  }
}
