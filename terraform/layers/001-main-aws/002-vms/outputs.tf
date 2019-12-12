output "k3s_bastion_private_ip" {
  value = aws_instance.k3s_bastion.private_ip
}

output "k3s_bastion_public_ip" {
  value = aws_instance.k3s_bastion.public_ip
}

output "k3s_masters_private_ip" {
  value = aws_instance.k3s_masters.*.private_ip
}

output "k3s_masters_public_ip" {
  value = aws_instance.k3s_masters.*.public_ip
}

output "k3s_nodes_private_ip" {
  value = aws_instance.k3s_nodes.*.private_ip
}

output "ansible_inventory" {
  value = <<EOF
[all:vars]
ansible_ssh_extra_args=-F ./ssh.cfg -o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p -F ./ssh.cfg ${aws_instance.k3s_bastion.public_ip}"

[bastions:vars]
ansible_ssh_extra_args=-F ./ssh.cfg

[bastions]
bastion ansible_host=${aws_instance.k3s_bastion.public_ip}

[masters]
${
  join("\n",
    formatlist("master-%s ansible_host=%s",
      split(",", replace(join(",", aws_instance.k3s_masters.*.private_ip), ".", "-")),
      aws_instance.k3s_masters.*.private_ip
    )
  )
}

[nodes]
${
  join("\n",
    formatlist("node-%s ansible_host=%s",
      split(",", replace(join(",", aws_instance.k3s_nodes.*.private_ip), ".", "-")),
      aws_instance.k3s_nodes.*.private_ip
    )
  )
}

[k3s-cluster:children]
masters
nodes
EOF
}
