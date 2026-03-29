pipeline {
    agent any

    environment {
        PATH = "/usr/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:${env.PATH}"
        TESTCONTAINERS_RYUK_DISABLED = "false"
        TESTCONTAINERS_WAIT_TIMEOUT = "120000"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/PipelineNinja/spring-petclinic.git'
            }
        }

        stage('Cleanup Old Containers') {
            steps {
                sh '''
                echo "Cleaning ALL containers to prevent port conflicts..."
                docker stop $(docker ps -aq --filter "label=org.testcontainers") 2>/dev/null || true
                docker rm $(docker ps -aq --filter "label=org.testcontainers") 2>/dev/null || true
                docker container prune -f || true
                '''
            }
        }

        stage('Build Application') {
            steps {
                sh 'mvn clean install -DskipTests -B'
            }
        }

        stage('Run Tests') {
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    sh '''
                    echo "Running tests with Testcontainers..."

                    echo "Docker status:"
                    docker ps -a

                    mvn test -B -DforkCount=1 -DreuseForks=false
                    '''
                }
            }
        }

        stage('SonarQube Analysis') {
            environment {
                SONAR_TOKEN = credentials('Sonar-Qube-Token')
            }
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn clean verify sonar:sonar -Dsonar.login=$SONAR_TOKEN -B -DskipTests'
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
                        terraform init -input=false -reconfigure
                        terraform apply -auto-approve -input=false
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Cleaning up test containers..."
            sh '''
            docker stop $(docker ps -aq --filter "label=org.testcontainers") 2>/dev/null || true
            docker rm $(docker ps -aq --filter "label=org.testcontainers") 2>/dev/null || true
            '''
            echo "Cleaning workspace"
            cleanWs()
        }
    }
}
