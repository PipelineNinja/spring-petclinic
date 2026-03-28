pipeline {
    agent any

    environment {
        PATH = "/usr/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:${env.PATH}"
        // Predefined Spring Boot datasource to reuse MySQL container
        SPRING_DATASOURCE_URL = "jdbc:mysql://localhost:3306/test"
        SPRING_DATASOURCE_USERNAME = "root"
        SPRING_DATASOURCE_PASSWORD = "root"
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
                sh 'mvn clean install -DskipTests -B' // skip tests for faster build
            }
        }

        stage('Prepare Database') {
            steps {
                sh '''
                # Remove existing container if exists
                docker ps -a | grep spring-petclinic-mysql && docker rm -f spring-petclinic-mysql || true

                # Start MySQL container for tests
                docker run -d --name spring-petclinic-mysql \
                    -e MYSQL_ROOT_PASSWORD=root \
                    -e MYSQL_DATABASE=test \
                    -p 3306:3306 mysql:9.5
                '''
            }
        }

        stage('Run Tests') {
            steps {
                timeout(time: 10, unit: 'MINUTES') { // increase timeout
                    sh 'mvn test -B' // batch mode
                }
            }
        }

        stage('SonarQube Analysis') {
            environment {
                SONAR_TOKEN = credentials('Sonar-Qube-Token')
            }
            steps {
                sh """
                mvn sonar:sonar \
                    -Dsonar.projectKey=SpringPetClinic \
                    -Dsonar.host.url=https://44.192.23.13:9090/ \
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
                    echo "Current directory:"
                    pwd

                    echo "Terraform files:"
                    ls -la

                    terraform init -input=false -reconfigure
                    terraform apply -auto-approve -input=false
                    '''
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
