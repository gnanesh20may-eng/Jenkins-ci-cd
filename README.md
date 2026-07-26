# Simple Jenkins CI/CD Pipeline (Build → Test → Deploy with Docker)

This project sets up a basic Jenkins pipeline that builds a Docker image,
runs tests inside it, pushes it to a registry, and deploys it as a running
container — triggered automatically on every commit.

## Files
- `Jenkinsfile` — the pipeline definition (place at repo root)
- `Dockerfile` — example app Dockerfile (replace with your own if you already have one)

## 1. Install Jenkins

**Option A — Docker (fastest for testing):**
```bash
docker run -d --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```
Then open `http://localhost:8080`, unlock with the initial admin password:
```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

**Option B — Cloud instance (EC2, GCE, etc.):** install Java 17+, then Jenkins via the
official apt/yum repo, and Docker separately so Jenkins can call the `docker` CLI.

Either way, make sure the Jenkins user has permission to run Docker:
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

## 2. Install required plugins

In Jenkins → Manage Jenkins → Plugins, install:
- Docker Pipeline
- GitHub Integration (or GitLab/Bitbucket equivalent)
- Pipeline

## 3. Add credentials

Manage Jenkins → Credentials → add a "Username with password" credential
with ID `dockerhub-credentials` (matches the Jenkinsfile) for your Docker
registry login.

## 4. Create the Pipeline job

1. New Item → Pipeline → name it (e.g. `myapp-cicd`)
2. Under "Pipeline", choose **Pipeline script from SCM**
3. SCM: Git → enter your repo URL and credentials
4. Script Path: `Jenkinsfile`
5. Save

## 5. Configure the commit trigger (webhook)

**GitHub:**
1. Repo → Settings → Webhooks → Add webhook
2. Payload URL: `http://<your-jenkins-url>/github-webhook/`
3. Content type: `application/json`
4. Event: "Just the push event"

In the Jenkins job config, under Build Triggers, enable **GitHub hook trigger
for GITScm polling** (this pairs with the `githubPush()` trigger in the
Jenkinsfile).

If your Jenkins isn't publicly reachable, use `pollSCM('H/2 * * * *')`
instead (already included as a commented alternative in the Jenkinsfile) —
Jenkins will check the repo every 2 minutes instead of relying on a webhook.

## 6. Test it

```bash
git add .
git commit -m "Trigger pipeline"
git push origin main
```

Then check **Jenkins dashboard → your job → Build History** — a new build
should start automatically. Click into it to watch Build → Test → Push →
Deploy execute stage by stage, and check `docker ps` on the Jenkins host to
confirm the container is running afterward.

## Notes / things to adapt
- Replace the `Test` stage command with your actual test runner.
- Replace `REGISTRY` in the Jenkinsfile with your real registry path.
- `Deploy` here does a simple `docker run` for demo purposes — for production
  you'd typically deploy to Kubernetes, ECS, or use `docker-compose`/`docker
  stack deploy` instead.
