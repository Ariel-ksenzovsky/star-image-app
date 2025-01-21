pipeline {
    agent any

    environment {
        SQL_FILE_PATH = '/tmp/init.sql'
        DB_PASSWORD = credentials('mysql_root')
        DOCKER_TOKEN_ID = 'docker-hub-token'
        DOCKER_IMAGE = 'arielk2511/star_meme_sql_compose'
        BUILD_NUM = "${BUILD_NUMBER}"
        AWS_CREDENTIALS = 'aws-creds'
        AWS_REGION = 'us-east-1'         // Replace with your AWS region
        AMI_ID = 'ami-01816d07b1128cd2d' // Replace with your AMI ID
        INSTANCE_TYPE = 't2.micro'      // Replace with your desired instance type
        KEY_NAME = 'instance-test'      // Replace with your EC2 key pair name
    }

    triggers {
        pollSCM('* * * * *')  // poll SCM every minute
    }

    stages {
        stage('Cleanup') {
            steps {
                sh '''
                docker stop docker-gif-app || echo "Container not running"
                docker rm docker-gif-app || echo "Container already removed"
                rm -rf ${WORKSPACE}/* || true
                git clone https://github.com/Ariel-ksenzovsky/star-image-app.git
                pwd
                docker compose down || true
                docker rmi $(docker images -q) -f || true
                '''
            }
        }

        stage('Set the Environment Variables') {
            steps {
                sh '''
                pwd
                id
                cp /home/arielk/.env /var/lib/jenkins/workspace/test1/star-image-app
                '''
            }
        }

        stage('Docker Login') {
            steps {
                script {
                    withCredentials([string(credentialsId: env.DOCKER_TOKEN_ID, variable: 'DOCKER_TOKEN')]) {
                        sh """
                        echo "$DOCKER_TOKEN" | docker login -u arielk2511 --password-stdin
                        """
                    }
                }
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                script {
                    sh '''
                    cd star-image-app
                    docker build -t ${DOCKER_IMAGE}:latest .
                    docker build -t ${DOCKER_IMAGE}:2.0.${BUILD_NUM} .
                    docker push ${DOCKER_IMAGE}:latest
                    docker push ${DOCKER_IMAGE}:2.0.${BUILD_NUM}
                    '''
                }
            }
        }

        stage('Prepare SQL File') {
            steps {
                sh '''
                cp star-image-app/init.sql ${SQL_FILE_PATH}
                '''
            }
        }

        stage('Run') {
            steps {
                sh '''
                docker ps -a
                id
                pwd
                cd star-image-app
                pwd
                docker compose up -d
                docker ps
                '''
            }
        }

        stage('Test-web') {
            steps {
                sh 'sleep 30'
                sh '''
                if ! docker logs docker-gif-app; then
                    echo "Container logs check failed"
                    exit 1
                fi
                if ! curl -f http://localhost:5000; then
                    echo "App is not reachable."
                    docker logs docker-gif-app
                    exit 1
                fi
                '''
            }
        }

        stage('Launch EC2 Instance') {
            steps {
                script {
                    // Create User Data script to install Docker and Docker Compose
                    def userData = '''#!/bin/bash
                        # Update the package repository and install Docker
                        sudo yum update -y
                        sudo yum install -y docker
                        sudo systemctl start docker
                        sudo systemctl enable docker

                        COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r '.tag_name')

                        # Install docker-compose
                        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                        sudo chmod +x /usr/local/bin/docker-compose

                        # Add ec2-user to the docker group to run docker without sudo
                        sudo usermod -a -G docker ec2-user
                    '''

                    // Run the AWS CLI command to launch an EC2 instance with the User Data script
                    def launchCommand = """
                        aws ec2 run-instances \
                            --image-id ${env.AMI_ID} \
                            --instance-type ${env.INSTANCE_TYPE} \
                            --key-name ${env.KEY_NAME} \
                            --region ${env.AWS_REGION} \
                            --network-interfaces '[{"NetworkInterfaceId":"eni-010d0c6160079f615","DeviceIndex":0}]' \
                            --user-data "${userData}" \
                            --output json
                            sleep 30
                    """

                    def result = sh(script: launchCommand, returnStdout: true).trim()
                    echo "EC2 Launch Command Result: ${result}"
            
                    // Extract InstanceId and ReservationId
                    def instanceId = sh(script: "echo '${result}' | jq -r '.Instances[0].InstanceId'", returnStdout: true).trim()
                    def reservationId = sh(script: "echo '${result}' | jq -r '.ReservationId'", returnStdout: true).trim()
                    echo "Launched EC2 Instance ID: ${instanceId}, Reservation ID: ${reservationId}"
            
                    // Optional: Retrieve Public IP
                    def publicIp = sh(script: """
                        aws ec2 describe-instances \
                        --instance-id ${instanceId} \
                        --query 'Reservations[0].Instances[0].PublicIpAddress' \
                        --output text \
                        --region ${env.AWS_REGION}
                    """, returnStdout: true).trim()
                    echo "Instance Public IP: ${publicIp}"

                    // Debug variables
                    echo "Public IP: ${publicIp}"
                    echo "Key Path: ${KEY_NAME}"

                    // Use SCP to copy multiple files to the EC2 instance
                    withCredentials([sshUserPrivateKey(credentialsId: 'instance-test', keyFileVariable: 'KEY_NAME', usernameVariable: 'ec2-user')]) {
                        sh """
                             scp -i ${KEY_NAME} -o StrictHostKeyChecking=no \
                                /var/lib/jenkins/workspace/test1/star-image-app/docker-compose.yml \
                                /var/lib/jenkins/workspace/test1/star-image-app/init.sql \
                                /var/lib/jenkins/workspace/test1/star-image-app/.env \
                                ec2-user@${publicIp}:/home/ec2-user/
                                sleep10

                            # Set environment variable on remote host
                                ssh -o StrictHostKeyChecking=no -i ${KEY_NAME} ec2-user@${publicIp} \
                                'echo 'DB_PASSWORD=${DB_PASSWORD}' >> /home/ec2-user/.env'
                                
                            # Run Docker Compose in remote session
                            ssh -o StrictHostKeyChecking=no -i ${KEY_NAME} ec2-user@${publicIp} << 'EOF'
                                sleep 5 
                                pwd 
                                sleep 30
                                sudo docker-compose up -d --quiet-pull
                            << EOF
                        """
                    }
                }
            }
        }
    }


    post {
        always {
            sh '''
            rm -f ${SQL_FILE_PATH}
            '''
        }
    }
}