portforward:
	kubectl port-forward svc/argocd-server -n argocd 8080:443

pre-production:
	argocd app create $@ \
    --dest-namespace argocd \
    --dest-server https://kubernetes.docker.internal:6443 \
    --repo https://github.com/caitlin615/argocd-demo.git \
    --path $@

.PHONY: pre-production portforward

init-argocd:
	@kubectl create namespace argocd
	@kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo "argocd admin password: '$$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2)'"
	@echo "First run 'make portforward' in a new terminal window"
	@echo "using command 'argocd login localhost:8080'"
	@echo "change password with 'argocd account update-password'"

deinit-argocd:
	kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl delete namespace argocd
