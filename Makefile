portforward:
	kubectl port-forward svc/argocd-server -n argocd 8080:443

pre-production:
	argocd app create $@ \
    --dest-namespace argocd \
    --dest-server https://kubernetes.docker.internal:6443 \
    --repo https://github.com/caitlin615/argo-demo.git \
    --path $@

.PHONY: pre-production portforward
