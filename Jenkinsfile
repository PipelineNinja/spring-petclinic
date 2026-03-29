pipeline {
    agent any

    environment {
        PATH = "/usr/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:${env.PATH}"

        // Disable Testcontainers issues in CI
        TESTCONTAINERS_RYUK_DISABLED = "true"
        TESTCONTAINERS_CHECKS_DISABLE = "true"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/PipelineNinja/spring-petclinic.git'
            }
        }

        stage('Cleanup Old Containers (SAFE)') {
            steps {
                sh '''
                echo "Cleaning old containers EXCEPT SonarQube..."

                # Remove only MySQL containers
                docker ps -a --filter "ancestor=mysql" -q | xargs -r docker rm -f
                # Remove PostgreSQL containers
                docker ps -a --filter "ancestor=postgres" -q | xargs -r docker rm -f
                # DO NOT touch SonarQube container
                echo "Ensuring SonarQube is preserved..."
                docker ps --filter "name=sonarqube"

                # Light cleanup only
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
                    echo "Running unit tests only (NO Testcontainers)..."

                    mvn test -B \
                    -Dtest=!MySqlIntegrationTests \
                    -Dspring.profiles.active=test \
                    -Dtestcontainers.enabled=false \
                    -DforkCount=1 \
                    -DreuseForks=false \
                    -DfailIfNoTests=false

                    echo "Unit Tests Completed!"
                    '''
                }
            }
        }

        stage('Ensure SonarQube Running') {
            steps {
                sh '''
                echo "Checking SonarQube container..."

                if ! docker ps --format "{{.Names}}" | grep -q "^sonarqube$"; then
                    echo "Starting existing SonarQube container..."
                    docker start sonarqube || {
                        echo "ERROR: SonarQube container not found!"
                        exit 1
                    }
                    sleep 15
                else
                    echo "SonarQube already running"
                fi
                '''
            }
        }

        stage('SonarQube Analysis') {
            environment {
                SONAR_TOKEN = credentials('Sonar-Qube-Token')
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
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    dir('/home/ec2-user/devops-projects/terraform-petclinic') {
                        sh '''
                        echo "Initializing Terraform..."

                        terraform init -reconfigure -input=false || \
                        terraform init -reconfigure -force-copy -input=false

                        terraform validate
                        terraform plan -input=false
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
            echo "Final Cleanup (SAFE)..."

            # Remove only MySQL containers
            docker ps -a --filter "ancestor=mysql" -q | xargs -r docker rm -f

            # DO NOT delete SonarQube container
            echo "Verifying SonarQube container still exists:"
            docker ps -a --filter "name=sonarqube"

            # Optional light cleanup
            docker container prune -f || true

            echo "Final Docker Status:"
            docker ps -a
            '''
            cleanWs()
        }
    }
}
