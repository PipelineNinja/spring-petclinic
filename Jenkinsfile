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
                sh 'mvn clean install -DskipTests'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'mvn test'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t kishormore123/spring-petclinic:latest .'
            }
        } 
        
       stage('SonarQube Analysis') {
           environment {
               SONAR_TOKEN = credentials('Sonar-Qube-Token') // your Jenkins credential
          } 

          steps {
              sh '''
              mvn sonar:sonar \
                     -Dsonar.projectKey=SpringPetClinic \
                     -Dsonar.host.url=http://44.213.66.196:9000/ \
                     -Dsonar.login=$SONAR_TOKEN
                 '''
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

                    # Use -reconfigure to ensure remote backend is correctly initialized
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
