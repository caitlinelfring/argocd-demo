production:
	@argocd app create $@ \
    --dest-namespace argocd \
    --dest-server https://kubernetes.docker.internal:6443 \
    --repo https://github.com/caitlin615/argocd-demo.git \
    --path apps \
    --helm-set environment=$@

pre-production:
	@argocd app create $@ \
    --dest-namespace argocd \
    --dest-server https://kubernetes.docker.internal:6443 \
    --repo https://github.com/caitlin615/argocd-demo.git \
    --path apps \
    --helm-set environment=$@

sync-pre-production:
	@argocd app sync pre-production
	@argocd app sync -l argocd.argoproj.io/instance=pre-production

sync-production:
	@argocd app sync production
	@argocd app sync -l argocd.argoproj.io/instance=production

deploy: pre-production production
sync: sync-pre-production sync-production

delete-pre-production:
	@argocd app delete pre-production

delete-production:
	@argocd app delete production

delete: delete-pre-production delete-production

.PHONY: production sync-production \
	delete-pre-production delete-production \
	pre-production sync-pre-production \
	deploy sync delete \
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

# argo-events install broke in https://github.com/argoproj/argo-events/commit/e7ecad29ec8d3f2b703f812a0e96a32745d3f8f6
AE_HASH=336cb65a412db9b5b1362f04534e28ac74e829d9

events-init:
	kubectl create namespace argo-events --dry-run=client -o yaml | kubectl apply -f -
	kubectl create secret generic github-access-token --namespace argo-events \
		--from-literal=username=caitlin615 --from-literal=password=$$(source .env && echo $$GITHUB_ACCESS_TOKEN) \
		--dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/$(AE_HASH)/manifests/namespace-install.yaml
	kubectl apply -n argo-events -f argo-events
	kubectl apply -n argo-events -f https://raw.githubusercontent.com/argoproj/argo/stable/manifests/install.yaml
	kubectl patch svc -n argo-events argo-server -p '{"spec": {"type": "LoadBalancer"}}'

dh-cred:
	@kubectl create secret docker-registry dockerhub --namespace argo-events \
		--docker-server=https://index.docker.io/v1/ \
		--docker-username=celfring \
		--docker-password=$$(source .env && echo $$DOCKERHUB_PASSWORD) \
		--docker-email=celfring@gmail.com \
		--dry-run=client -o yaml | kubectl apply -f -

events-deinit:
	kubectl delete -n argo-events -f argo-events
	kubectl delete -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/$(AE_HASH)/manifests/namespace-install.yaml
	kubectl delete -n argo-events -f https://raw.githubusercontent.com/argoproj/argo/stable/manifests/install.yaml
