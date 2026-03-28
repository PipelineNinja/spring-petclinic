pipeline {
    agent any

    environment {
        PATH = "/usr/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:${env.PATH}"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/PipelineNinja/spring-petclinic.git'
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
                    echo "Cleaning ONLY old MySQL containers (safe)..."

                    docker ps -a | grep mysql | awk '{print $1}' | xargs -r docker rm -f

                    echo "Running tests (Testcontainers should start MySQL)..."
                    mvn test -B
                    '''
                }
            }
        }

        stage('SonarQube Analysis') {
            environment {
                SONAR_TOKEN = credentials('Sonar-Qube-Token')
            }
            steps {
                sh """
                mvn org.sonarsource.scanner.maven:sonar-maven-plugin:4.0.0.4121:sonar \
                    -Dsonar.projectKey=SpringPetClinic \
                    -Dsonar.host.url=https://44.192.71.28:9000 \
                    -Dsonar.login=\$SONAR_TOKEN -B
                """
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
                dir('/home/ec2-user/devops-projects/terraform-petclinic') {
                    sh '''
                    terraform init -input=false -reconfigure
                    terraform apply -auto-approve -input=false
                    '''
                }
            }
        }
    }

    post {
        always {
            echo "Cleaning workspace only (SonarQube safe)"
            cleanWs()
        }
    }
}
