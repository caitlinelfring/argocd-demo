deploy:
	argocd app create apps \
    --dest-namespace argocd \
    --dest-server https://kubernetes.default.svc \
    --repo https://github.com/caitlin615/argocd-demo.git \
    --path apps \
    --revision pixel

sync:
	argocd app sync apps
	argocd app sync -l argocd.argoproj.io/instance=apps

delete:
	argocd app delete apps

.PHONY: deploy sync delete \
	init deinit \
	init-argocd deinit-argocd \
	watch

init: init-argocd
deinit: delete deinit-argocd

init-argocd:
	helm3 repo add argo https://argoproj.github.io/argo-helm
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl create namespace rtr --dry-run=client -o yaml | kubectl apply -f -
	helm3 upgrade argocd --namespace argocd argo/argo-cd -f argocd-init/values.yaml --wait --install

secrets:
	@kubectl create secret --namespace rtr docker-registry gcr-json-key \
		--docker-server=gcr.io \
		--docker-username=_json_key \
		--docker-password="$$(cat gcr.json)" \
		--docker-email=foo@example.com
	@kubectl patch serviceaccount --namespace rtr default -p '{"imagePullSecrets": [{"name": "gcr-json-key"}]}'
	@kubectl create secret generic environment --namespace rtr --from-literal=environment=stage
	@kubectl create secret generic templated-properties-env-vars --namespace rtr --from-literal=FOO=BAR
	@kubectl create secret generic github-access-token --namespace argocd --from-literal=username=caitlin615 --from-literal=password=$$(source .env && echo $$GITHUB_ACCESS_TOKEN)

deinit-argocd:
	helm3 uninstall argocd --namespace argocd
	kubectl delete namespace argocd
	kubectl delete namespace rtr

watch:
	watch "kubectl get pods -A --sort-by=status.startTime | awk 'NR<2{print \$$0;next}{print \$$0| \"tail -r\"}'"
