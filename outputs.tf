# Output variables

# Since fake_db resides in private subnet, this variable should be empty
output "db_public_ip" {
  value = "${aws_instance.fake_db.public_ip}"
}

output "db_private_ip" {
  value = "${aws_instance.fake_db.private_ip}"
}

output "webserver_public_ip" {
  value = "${aws_instance.fake_webserver.public_ip}"
}
