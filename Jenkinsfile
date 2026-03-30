pipeline {
    agent any
    environment {
        PATH = "/usr/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:${env.PATH}"
        TESTCONTAINERS_RYUK_DISABLED = "true"
        TESTCONTAINERS_CHECKS_DISABLE = "true"
        TESTCONTAINERS_ENABLED = "false"
    }
    stages {
        stage('Cleanup Old Containers') {
            steps {
                sh '''
                echo "Cleaning old containers..."
                docker ps -a --filter "ancestor=mysql" -q | xargs -r docker rm -f
                docker ps -a --filter "ancestor=postgres" -q | xargs -r docker rm -f
                docker container prune -f || true
                '''
            }
        }
        stage('Build Application') {
            steps {
                sh 'mvn clean install -DskipTests -B'
            }
        }
        stage('Run Unit Tests (CI Safe)') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    sh '''
                    echo "Running unit tests only (NO Testcontainers, NO DB)..."
                    mvn test -B \
                      -Dtest="!**IntegrationTest,!**IT" \
                      -Dspring.profiles.active=test \
                      -Dspring.datasource.url=jdbc:h2:mem:testdb \
                      -Dspring.datasource.driver-class-name=org.h2.Driver \
                      -Dspring.jpa.database-platform=org.hibernate.dialect.H2Dialect \
                      -Dspring.datasource.username=sa \
                      -Dspring.datasource.password= \
                      -Dtestcontainers.enabled=false \
                      -DforkCount=1 \
                      -DreuseForks=false \
                      -DfailIfNoTests=false \
                      -Dsurefire.useFile=false
                    echo "Unit Tests Completed!"
                    '''
                }
            }
        }
        stage('SonarQube Analysis') {
            environment {
                SONAR_TOKEN = credentials('Sonar')
            }
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                    mvn verify sonar:sonar -B \
                    -DskipTests \
                    -Dsonar.login=$SONAR_TOKEN
                    '''
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t kishormore123/spring-petclinic:latest .'
            }
        }
        stage('Trivy Scan') {   // <-- Updated Trivy stage
            environment {
                TRIVY_CACHE_DIR = "/home/jenkins/trivy-cache"
            }
            steps {
                script {
                    sh 'trivy image --cache-dir $TRIVY_CACHE_DIR --severity HIGH,CRITICAL kishormore123/spring-petclinic:latest'
                }
            }
        }
        stage('Docker Login & Push') {
            environment {
                DOCKERHUB_CREDS = credentials('dockerhub-creds')
            }
            steps {
                sh '''
                echo $DOCKERHUB_CREDS_PSW | docker login -u $DOCKERHUB_CREDS_USR --password-stdin
                docker push kishormore123/spring-petclinic:latest
                '''
            }
        }
        stage('Terraform Init & Apply') {
            environment {
                AWS_ACCESS_KEY_ID     = credentials('AWS-CRED')
                AWS_SECRET_ACCESS_KEY = credentials('AWS-CRED')
            }
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    dir('/home/ec2-user/devops-projects/terraform-petclinic') {
                        sh '''
                        echo "Cleaning old Terraform cache..."
                        rm -rf .terraform
                        rm -f .terraform.lock.hcl
                        echo "Initializing Terraform with S3 + DynamoDB backend..."
                        terraform init -reconfigure \
                          -backend-config="bucket=petclinic-terraform-state-kishor" \
                          -backend-config="key=petclinic/terraform.tfstate" \
                          -backend-config="region=us-east-1" \
                          -backend-config="dynamodb_table=terraform-lock" \
                          -backend-config="encrypt=true"
                        echo "Selecting workspace..."
                        terraform workspace select dev || terraform workspace new dev
                        echo "Validating..."
                        terraform validate
                        echo "Planning..."
                        terraform plan -input=false
                        echo "Applying..."
                        terraform apply -auto-approve -input=false
                        '''
                    }
                }
            }
        }
    }
    post {
        always {
            sh '''
            echo "Final Cleanup..."
            docker ps -a --filter "ancestor=mysql" -q | xargs -r docker rm -f
            docker ps -a --filter "ancestor=postgres" -q | xargs -r docker rm -f
            docker container prune -f || true
            echo "Final Docker Status:"
            docker ps -a
            '''
            cleanWs()
        }
    }
}
