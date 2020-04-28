deploy:
	@argocd app create apps \
    --dest-namespace argocd \
    --dest-server https://kubernetes.docker.internal:6443 \
    --repo https://github.com/caitlin615/argocd-demo.git \
    --path apps \
    --revision pixel

sync:
	@argocd app sync production
	@argocd app sync -l argocd.argoproj.io/instance=apps

delete:
	@argocd app delete apps

.PHONY: deploy sync delete \
	init deinit \
	init-argocd deinit-argocd \
	watch

init: init-argocd
deinit: delete deinit-argocd

init-argocd:
	@helm3 repo add argo https://argoproj.github.io/argo-helm
	@kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	@helm3 install argocd --namespace argocd argo/argo-cd -f argocd-init/values.yaml --wait
	@echo "Default argocd admin password, be sure to change it! '$$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2)'"

deinit-argocd:
	@helm3 uninstall argocd --namespace argocd
	@kubectl delete namespace argocd

watch:
	@watch "kubectl get pods -A --sort-by=status.startTime | awk 'NR<2{print \$$0;next}{print \$$0| \"tail -r\"}'"
