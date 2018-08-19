resource "aws_instance" "openshift-master" {
  count = 3
  ami = "${lookup(var.amis, var.region)}"
  instance_type = "${var.instance_type}"
  availability_zone = "${var.region}${element(var.zones, count.index)}"
  ebs_optimized = false
  key_name = "${var.key_name}"
  security_groups = ["default"]
  tags = {
    Name = "openshift-master-${count.index+1}"
  }
  root_block_device = {
    volume_type = "standard"
    volume_size = "20"
    delete_on_termination = true
  }

  provisioner "remote-exec" {
    inline = [ "sudo subscription-manager unregister" ]
    when = "destroy"
    connection {
      type = "ssh"
      host = "${self.public_dns}"
      user = "${var.username}"
      private_key = "${file(var.private_key)}"
    }
  }
}

resource "aws_instance" "openshift-node" {
  count = 4
  ami = "${lookup(var.amis, var.region)}"
  instance_type = "${var.instance_type}"
  availability_zone = "${var.region}${element(var.zones, count.index)}"
  ebs_optimized = false
  key_name = "${var.key_name}"
  security_groups = ["default"]
  tags = {
    Name = "openshift-node-${count.index+1}"
  }
  root_block_device = {
    volume_type = "standard"
    volume_size = "20"
    delete_on_termination = true
  }
  ebs_block_device = {
    volume_type = "gp2"
    volume_size = "40"
    delete_on_termination = true
    device_name = "/dev/sdb"
  }

  provisioner "remote-exec" {
    inline = [ "sudo subscription-manager unregister" ]
    when = "destroy"
    connection {
      type = "ssh"
      host = "${self.public_dns}"
      user = "${var.username}"
      private_key = "${file(var.private_key)}"
    }
  }
}

resource "aws_instance" "openshift" {
  ami = "${lookup(var.amis, var.region)}"
  instance_type = "${var.instance_type}"
  ebs_optimized = false
  key_name = "${var.key_name}"
  security_groups  = ["default"]
  tags = {
    Name = "openshift"
  }

  provisioner "remote-exec" {
    inline = [ "sudo subscription-manager unregister" ]
    when = "destroy"
    connection {
      type = "ssh"
      host = "${self.public_dns}"
      user = "${var.username}"
      private_key = "${file(var.private_key)}"
    }
  }
}

resource "aws_eip" "openshift-master" {
  count = 3
  instance = "${aws_instance.openshift-master.*.id[count.index]}"
}

resource "aws_eip" "openshift-node" {
  count = 4
  instance = "${aws_instance.openshift-node.*.id[count.index]}"
}

resource "aws_eip" "openshift" {
  instance = "${aws_instance.openshift.id}"
}

resource "aws_route53_record" "openshift-master" {
  count = 3
  zone_id = "${var.zone_id}"
  name = "openshift-master-${count.index+1}"
  type = "A"
  ttl = "300"
  records = ["${aws_eip.openshift-master.*.public_ip[count.index]}"]
}

resource "aws_route53_record" "openshift-node" {
  count = 4
  zone_id = "${var.zone_id}"
  name = "openshift-node-${count.index+1}"
  type = "A"
  ttl = "300"
  records = ["${aws_eip.openshift-node.*.public_ip[count.index]}"]
}

resource "aws_route53_record" "openshift" {
  zone_id = "${var.zone_id}"
  name = "openshift"
  type = "A"
  ttl = "300"
  records = ["${aws_eip.openshift.public_ip}"]
}

resource "aws_route53_record" "openshift-apps" {
  zone_id = "${var.zone_id}"
  name = "*.openshift"
  type = "CNAME"
  ttl = "300"
  records = ["${aws_route53_record.openshift-node.*.fqdn[0]}"]
}
