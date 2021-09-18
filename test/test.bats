setup_file () {
    # startup the docker-compose project 
    docker-compose --env-file test/env_test up -d     
}
setup () {
    load 'test_helper/bats-support/load' # this is required by bats-assert!
    load 'test_helper/bats-assert/load'
}

teardown_file () {
    # end the docker-compose project
    docker-compose down
}

tester () {
    docker run -it --rm --network=tinydyndns_default tester sh -c "$*"
}

@test "can telnet into updater's port 22" {
    run tester "echo -e \'\x1dclose\x0d\' | telnet updater 22"
    assert_success
}

@test "can ssh into updater" {
    run tester "ssh -o \"StrictHostKeyChecking no\" -i /etc/ssh/hostkey -q dyndns@updater"
    # fail because this returns exit 1
    assert_failure
    echo "Illegal number of arguments." | assert_output
}

@test "can get a DNS record" {
    dig -p 1053 @localhost example.com
}

@test "correct default soa" {
    lastmod=$(stat -c %Y test/data_test)
    run dig +short -p 1053 SOA @localhost example.com
    assert_output "ns1.example.com. hostmaster.example.com. ${lastmod} 16384 2048 1048576 2560"
}

@test "correct default A records" {
    run dig +short -p 1053 A @localhost ns1.example.com
    assert_output "1.1.1.1"

    run dig +short -p 1053 A @localhost ns2.example.com
    assert_output "2.2.2.2"

    run dig +short -p 1053 A @localhost example.com
    assert_output "3.3.3.3"

    run dig +short -p 1053 A @localhost *.example.com
    assert_output "4.4.4.4"
}

@test "correct default AAAA records" {
    run dig +short -p 1053 AAAA @localhost ns1.example.com
    assert_output "2606:4700:4700::1111"

    run dig +short -p 1053 AAAA @localhost ns2.example.com
    assert_output "2606:4700:4700::2222"

    run dig +short -p 1053 AAAA @localhost example.com
    assert_output "2606:4700:4700::3333"

    run dig +short -p 1053 AAAA @localhost *.example.com
    assert_output "2606:4700:4700::4444"
}