dir = test_dir
malicious_dir = quarantine
interval = 5

run: setup
	bash ./antivirusd.sh $(dir) $(malicious_dir) $(interval)

restore: setup
	bash ./restore.sh $(dir) $(malicious_dir)

setup:
	mkdir -p $(malicious_dir)
	mkdir -p $(dir)