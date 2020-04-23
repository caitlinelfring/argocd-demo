portforward:
	kubectl port-forward svc/argocd-server -n argocd 8080:443


production:
	argocd app create $@ \
    --dest-namespace argocd \
    --dest-server https://kubernetes.docker.internal:6443 \
    --repo https://github.com/caitlin615/argocd-demo.git \
    --path apps \
    --values apps/values-$@.yaml

pre-production:
	argocd app create $@ \
    --dest-namespace argocd \
    --dest-server https://kubernetes.docker.internal:6443 \
    --repo https://github.com/caitlin615/argocd-demo.git \
    --path apps \
    --values apps/values-$@.yaml

sync-pre-production:
	argocd app sync pre-production


sync-production:
	argocd app sync production

.PHONY: pre-production portforward init-argocd deinit argocd sync-pre-production \
	production sync-production

init-argocd:
	@kubectl create namespace argocd
	@kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo "argocd admin password: '$$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2)'"
	@echo "First run 'make portforward' in a new terminal window"
	@echo "using command 'argocd login localhost:8080'"
	@echo "change password with 'argocd account update-password'"
	@echo "next, run 'argocd cluster add' and choose a cluster to connect add, ie 'argocd cluster add docker-desktop'"

deinit-argocd:
	kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl delete namespace argocd
