create_cluster:
        @if [ -z "$(worker)" ]; then\
                ansible-playbook create-cluster.yml -i inventory; \
        else \
                ansible-playbook create-cluster.yml -i inventory -e "worker_node_count=$(worker)"; \
        fi

delete_cluster:
        @ansible-playbook delete-cluster.yml -i inventory


get_kubeconfig:
        @if [[ -f "kube-cluster/kubeconfig/admin.conf" ]]; then\
                cat kube-cluster/kubeconfig/admin.conf; \
        else \
                echo "[INFO] No cluster kubeconfig present. Please provision a cluster using \`make create-cluster\`"; \
        fi


get_ec2_private_key:
        @if [[ -f "keys/kubernetes-key.pem" ]]; then\
                cat keys/kubernetes-key.pem; \
        else \
                echo "[INFO] No keys present. Please provision a cluster using \`make create-cluster\`"; \
        fi
