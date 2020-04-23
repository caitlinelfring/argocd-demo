argocd-demo
---

[Argo CD](https://argoproj.github.io/argo-cd/) is a declarative, GitOps continuous delivery tool for Kubernetes.

This project is a POC to show the full pipeline of a deployment with multiple "environments"
from within a Docker for Mac Kubernetes cluster, requiring no external resources.

**If you would like to try out the full GitOps feature set of Argo CD,
be sure to fork this repo first so you can push your own commits to trigger changes**.

Fork this repo here: https://github.com/caitlin615/argocd-demo/fork

# Requirements
- [Docker Desktop on Mac](https://docs.docker.com/docker-for-mac/install/)
- [Kubernetes cluster enabled](https://docs.docker.com/docker-for-mac/#kubernetes)
- [Argo CLI](https://argoproj.github.io/argo-cd/getting_started/#2-download-argo-cd-cli)
  - `brew tap argoproj/tap && brew install argoproj/tap/argocd`

# Setup
## Install Argo CD
Install Argo CD
```bash
make init-argocd
```
This will expose Argo CD at `http://localhost:8080` and output the default password for the `admin` user.
Change the password in the UI, or with `argocd login localhost:8080`, then `argocd account update-password`.

## Add your cluster to Argo CD
This isn't super necessary, but allows us to pretend we're running argo on a different
cluster from where we're deploying our applications.

```bash
# List available clusters
argocd cluster add
# To add docker-deskop cluster
argocd cluster add docker-desktop
```

## Set up nginx ingress controller
```bash
make nginx
```

Add the following to your `/etc/hosts`. The ingress controller uses hostname matching for routing,
so this is needed to route your requests to the correct location.
```
127.0.0.1 guestbook.pre-production.local guestbook.production.local
```

# Deploy "Parent" Applications
For the purposes of this demo, we will be using the [**app of apps** pattern](https://argoproj.github.io/argo-cd/operator-manual/cluster-bootstrapping/). This means we create an app
that will create all of our apps.

![](https://argoproj.github.io/argo-cd/assets/application-of-applications.png)

There are two parent applications that represent each "environment":
* `production`
* `pre-production`

## Deploying
```bash
make deploy

# Or deploy parent/child applications individually
make pre-production
make production
```

### Force a sync
Now that you've deployed both apps, and thus, their child apps, they will not automatically sync.
By default, Argo CD polls with the git repositories every 3 minutes to detect manifest changes
You can wait the three minutes, or you can manually triggering a sync. The other option
is setting up a [git webhook](https://argoproj.github.io/argo-cd/operator-manual/webhook/)
(which we aren't doing for this demo).
```bash
make sync

# Or sync parent/child applications individually
make sync-pre-production
make sync-production
```

You will now see something like this at http://localhost:8080.
The top two are the guestbook applications, and the bottom two are the parent applications.

![](./assets/apps.png)

# Access Guestbook

Access each guestbook here:
* http://guestbook.pre-production.local
* http://guestbook.production.local

# Not included
Not included in this POC are:
* RBAC
* TLS
* User/Project management
* Metrics
* [Secrets](https://argoproj.github.io/argo-cd/operator-manual/secret-management/)
* [Git Webhook](https://argoproj.github.io/argo-cd/operator-manual/webhook/)
* CI
* Initialization of `argocd` via helm and
* HA
