pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')  
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY') 
        IMAGE_NAME = "devops-ecs-app"
        REPO = "http://130.131.164.192:8082/artifactory/data-devin-docker-local/"
    }

    stages {
        stage('Checkout') {
            steps {
                // Checkout the code from GitHub
                git branch: 'main', url: 'https://github.com/org-ms-02/DevOps.git'
            }
        }

        stage('Build Lambda Functions') {
            steps {
                // Build the Lambda functions (for user-auth and payment-processing)
                dir('backend/user-authentication') {
                    sh 'npm install && npm run build'
                }
                dir('backend/payment-processing') {
                    sh 'npm install && npm run build'
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                // Build Docker images for ECS services
                dir('backend/product-catalog') {
                    sh 'docker build -t $IMAGE_NAME .'
                }
            }
        }

        stage('Test Lambda Functions') {
            steps {
                // Run unit tests for AWS Lambda functions
                dir('backend/user-authentication') {
                    sh 'npm run test'
                }
                dir('backend/payment-processing') {
                    sh 'npm run test'
                }
            }
        }

        stage('Push Docker Image to JFrog') {
            steps {
                // Push Docker image to JFrog Artifactory (for ECS deployment)
                withCredentials([usernamePassword(
                    credentialsId: '05b290d8-e5cb-4617-9bb9-a0b2dd218414',
                    usernameVariable: 'USERNAME',
                    passwordVariable: 'PASSWORD'
                )]) {
                    sh """
                    docker login -u $USERNAME -p $PASSWORD http://130.131.164.192:8082/
                    docker tag $IMAGE_NAME 130.131.164.192:8081/data-devin-docker-local/$IMAGE_NAME:$IMAGE_NAME
                    docker push 130.131.164.192:8081/data-devin-docker-local/$IMAGE_NAME:$IMAGE_NAME
                    """
                }
            }
        }

        stage('Create Lambda Artifacts') {
            steps {
                // Package Lambda functions as zip artifacts
                dir('backend/user-authentication') {
                    sh 'zip -r user-auth.zip .'
                }
                dir('backend/payment-processing') {
                    sh 'zip -r payment-processing.zip .'
                }
            }
        }

        stage('Upload Artifacts to JFrog') {
            steps {
                // Upload Lambda artifacts to JFrog
                withCredentials([usernamePassword(
                    credentialsId: '05b290d8-e5cb-4617-9bb9-a0b2dd218414',
                    usernameVariable: 'USERNAME',
                    passwordVariable: 'PASSWORD'
                )]) {
                    sh """
                    jfrog rt u "backend/user-authentication/user-auth.zip" "jfrog.example.com/lambda-artifacts/user-auth.zip"
                    jfrog rt u "backend/payment-processing/payment-processing.zip" "jfrog.example.com/lambda-artifacts/payment-processing.zip"
                    """
                }
            }
        }

        // Step for Terraform to Create the Infrastructure (including Lambda)
        stage('Terraform Apply - Deploy Infrastructure') {
            steps {
                dir('infrastructure/terraform') {
                    withCredentials([[ 
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: '289d6517-d555-4981-a6fb-d5f34ea5a3fd'
                    ]]) {
                        sh '''
                        echo "Using AWS credentials"
                        aws sts get-caller-identity
                        terraform init
                        terraform apply -auto-approve
                        '''
                    }
                }
            }
        }

        stage('Manual Approval') {
            steps {
                script {
                    input message: "Proceed to deploy on ECS?", ok: "Deploy"
                }
            }
        }

        // Deploy Lambda functions after they have been created with Terraform
        stage('Deploy Lambda Functions') {
            steps {
                // Deploy Lambda functions using AWS CLI after infrastructure is created
                sh 'aws lambda update-function-code --function-name user-authentication --zip-file fileb://backend/user-authentication/user-auth.zip'
                sh 'aws lambda update-function-code --function-name payment-processing --zip-file fileb://backend/payment-processing/payment-processing.zip'
            }
        }

        stage('ECS Deployment') {
            steps {
                dir('infrastructure/terraform') {
                    withCredentials([[ 
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: '289d6517-d555-4981-a6fb-d5f34ea5a3fd'
                    ]]) {
                        sh '''
                        echo "Deploying to ECS..."
                        terraform apply -auto-approve
                        '''
                    }
                }
            }
        }
    }
}
