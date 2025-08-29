pipeline {
    agent any

    environment {
        IMAGE_NAME = "devops-ecs-app"
        REPO = "http://130.131.164.192:8082/artifactory/data-devin-docker-local/"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/org-ms-02/DevOps.git'
            }
        }

        stage('Build Lambda Functions') {
            steps {
                dir('serverless-ecommerce-app/backend/user-authentication') {
                    sh 'npm install'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                dir('serverless-ecommerce-app/backend/product-catalog') {
                    sh 'docker build -t $IMAGE_NAME .'
                }
            }
        }

        stage('Test Lambda Functions') {
            steps {
                dir('serverless-ecommerce-app/backend/user-authentication') {
                    sh 'npm run test'
                }
                dir('serverless-ecommerce-app/backend/payment-processing') {
                    sh 'npm run test'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonarQube') {
                    withCredentials([string(credentialsId: '84966b2c-0d0a-48d8-b18e-eff9ff3a5fc3', variable: 'SONAR_TOKEN')]) {
                        sh '''
                            sonar-scanner \
                              -Dsonar.projectKey=devops-ecs-app \
                              -Dsonar.sources=. \
                              -Dsonar.host.url=$SONAR_HOST_URL \
                              -Dsonar.login=$SONAR_TOKEN
                        '''
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Push Docker Image to JFrog') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: '05b290d8-e5cb-4617-9bb9-a0b2dd218414',
                    usernameVariable: 'USERNAME',
                    passwordVariable: 'PASSWORD'
                )]) {
                    sh """
                        docker login -u $USERNAME -p $PASSWORD http://130.131.164.192:8082/
                        docker tag $IMAGE_NAME 130.131.164.192:8082/data-devin-docker-local/$IMAGE_NAME:$IMAGE_NAME
                        docker push 130.131.164.192:8082/data-devin-docker-local/$IMAGE_NAME:$IMAGE_NAME
                    """
                }
            }
        }

        stage('Create Lambda Artifacts') {
            steps {
                dir('serverless-ecommerce-app/backend/user-authentication') {
                    sh 'zip -r user-auth.zip .'
                }
                dir('serverless-ecommerce-app/backend/payment-processing') {
                    sh 'zip -r payment-processing.zip .'
                }
            }
        }

        stage('Upload Artifacts to JFrog') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'a53b0834-9a22-4e78-9ba6-4a09c326a9d1',
                    usernameVariable: 'USERNAME',
                    passwordVariable: 'PASSWORD'
                )]) {
                    sh '''
                        jf config remove artifactory-server --quiet || true
                        jf config add artifactory-server \
                            --url=http://130.131.164.192:8082/ \
                            --user=$USERNAME \
                            --password=$PASSWORD \
                            --interactive=false

                        jf rt upload "serverless-ecommerce-app/backend/user-authentication/user-auth.zip" "data-devin-local-generic/user-auth.zip" --server-id=artifactory-server
                        jf rt upload "serverless-ecommerce-app/backend/payment-processing/payment-processing.zip" "data-devin-local-generic/payment-processing.zip" --server-id=artifactory-server
                    '''
                }
            }
        }

        stage('Terraform Apply - Deploy Infrastructure') {
            steps {
                dir('serverless-ecommerce-app/terraform') {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: '289d6517-d555-4981-a6fb-d5f34ea5a3fd',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
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

        stage('Deploy Lambda Functions') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: '289d6517-d555-4981-a6fb-d5f34ea5a3fd',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        aws lambda update-function-code --function-name user-authentication --zip-file fileb://serverless-ecommerce-app/backend/user-authentication/user-auth.zip --region us-east-1
                        aws lambda update-function-code --function-name payment-processing --zip-file fileb://serverless-ecommerce-app/backend/payment-processing/payment-processing.zip --region us-east-1
                    '''
                }
            }
        }

        stage('ECS Deployment') {
            steps {
                dir('serverless-ecommerce-app/terraform') {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: '289d6517-d555-4981-a6fb-d5f34ea5a3fd',
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
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
