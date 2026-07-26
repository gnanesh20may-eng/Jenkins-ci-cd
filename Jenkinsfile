// Jenkinsfile — Declarative Pipeline for Build -> Test -> Deploy using Docker
// Place this file at the root of your project's Git repository.

pipeline {

    agent any

    // ---- Configuration you should adjust for your project ----
    environment {
        IMAGE_NAME       = "myapp"                          // Docker image name
        IMAGE_TAG        = "${env.BUILD_NUMBER}"            // Tag each build uniquely
        REGISTRY         = "docker.io/your-dockerhub-user"  // Change to your registry
        CONTAINER_NAME   = "myapp-container"
        DEPLOY_PORT      = "8080"
        DOCKERHUB_CREDS  = credentials('dockerhub-credentials') // Jenkins credential ID
    }

    options {
        // Keep only the last 10 builds to save disk space
        buildDiscarder(logRotator(numToKeepStr: '10'))
        // Prevent overlapping runs of the same pipeline
        disableConcurrentBuilds()
        timestamps()
    }

    // Trigger automatically when Jenkins receives a webhook from GitHub/GitLab/Bitbucket
    // (Requires the corresponding plugin + webhook configured in the repo settings)
    triggers {
        githubPush()
        // Alternative if webhooks aren't available: poll SCM every 2 minutes
        // pollSCM('H/2 * * * *')
    }

    stages {

        stage('Checkout') {
            steps {
                echo "Checking out source code..."
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo "Building Docker image ${IMAGE_NAME}:${IMAGE_TAG}..."
                sh """
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
                """
            }
        }

        stage('Test') {
            steps {
                echo "Running tests inside a throwaway container..."
                sh """
                    docker run --rm ${IMAGE_NAME}:${IMAGE_TAG} \
                        sh -c 'npm install && npm test || pytest || true'
                """
                // Replace the command above with whatever your project's
                // real test runner is (npm test, pytest, mvn test, go test, etc.)
            }
        }

        stage('Push to Registry') {
            when {
                branch 'main'   // Only push/deploy from the main branch
            }
            steps {
                echo "Pushing image to registry..."
                sh """
                    echo "${DOCKERHUB_CREDS_PSW}" | docker login -u "${DOCKERHUB_CREDS_USR}" --password-stdin
                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                    docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                echo "Deploying new container..."
                sh """
                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true
                    docker run -d --name ${CONTAINER_NAME} \
                        -p ${DEPLOY_PORT}:${DEPLOY_PORT} \
                        ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully — build #${env.BUILD_NUMBER}"
        }
        failure {
            echo "❌ Pipeline failed — check the console log for build #${env.BUILD_NUMBER}"
        }
        always {
            sh "docker image prune -f || true"
        }
    }
}
