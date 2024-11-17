.DEFAULT_GOAL := install

ANSIBLE_PATH=ansible
TF_PATH=terraform
TF_COMMAND=terraform -chdir=${TF_PATH}
AEGEA_SRC_URL=https://blogengine.me/download/e2_distr_v4134.zip
AEGEA_ZIP_FILE=e2_distr_v4134.zip
AEGEA_DIR=e2_distr_v4134

.PHONY: scale-images
scale-images:
	@echo "Scaling images."
	@cd images && for i in {first.png,created.png}; do ffmpeg -i $$i -vf "scale=400:-1" $${i}.scaled.png -y; done

.PHONY: get-aegea
get-aegea:
	@echo "Downloading aegea and repackaging."
	@curl -O ${AEGEA_SRC_URL}
	@unzip ${AEGEA_ZIP_FILE} -d ${AEGEA_DIR}
	@tar czfv ${AEGEA_DIR}.tar.gz ${AEGEA_DIR}
	@rm -r ${AEGEA_DIR} ${AEGEA_ZIP_FILE}

.PHONY: terraform-apply
terraform-apply:
	@echo "Running terraform."
	@${TF_COMMAND} init
	@${TF_COMMAND} apply -auto-approve

.PHONY: terraform-destroy
terraform-destroy:
	@echo "Destroying terraform."
	@${TF_COMMAND} destroy

.PHONY: terraform-providers
terraform-providers:
	@echo "Installing terraform providers."
	@${TF_COMMAND} providers lock

.PHONY: ssh
ssh:
	@echo "SSH into the instance."
	@export server_ip=$$(${TF_COMMAND} output --raw server_ip) && \
    	ssh -i ${TF_PATH}/private_key root@$${server_ip}

.PHONY: ansible-playbook
ansible-playbook:
	@echo "Running ansible playbook."
	@ansible-playbook -i ${ANSIBLE_PATH}/inventory.yml ${ANSIBLE_PATH}/apache.yml $(ARGS)

.PHONY: install
install: get-aegea terraform-apply ansible-playbook
	@echo "Installation complete."
