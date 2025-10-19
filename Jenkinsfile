pipeline {
    agent any

    environment {
        // AWS credentials stored in Jenkins as Secret Text
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Java App') {
            steps {
                echo "Building Java app with Maven..."
                sh 'set -e; mvn clean package -DskipTests'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.war', fingerprint: true
                }
            }
        }

        stage('Terraform Init & Plan') {
            steps {
                dir('terraform-infra') {
                    withEnv([
                        "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}",
                        "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"
                    ]) {
                        sh '''
                            set -e
                            terraform init -input=false
                            terraform plan -out=tfplan
                        '''
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform-infra') {
                    withEnv([
                        "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}",
                        "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"
                    ]) {
                        sh '''
                            set -e
                            terraform apply -input=false -auto-approve tfplan
                        '''
                    }
                }
            }
        }

        stage('Prepare Ansible Inventory') {
            steps {
                script {
                    // Capture the Terraform output (public IP)
                    def ip = sh(script: "cd terraform-infra && terraform output -raw instance_ip", returnStdout: true).trim()
                    writeFile file: 'ansible/inventory.ini', text: "[app]\n${ip} ansible_user=ec2-user ansible_ssh_private_key_file=ansible/jenkins_key.pem"
                    echo "Inventory created with IP: ${ip}"
                }
            }
        }

        stage('Ansible Deploy') {
            steps {
                dir('ansible') {
                    sh '''
                        set -e
                        ansible-playbook -i inventory.ini playbook.yml
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully!"
        }
        failure {
            echo "Pipeline failed. Check logs for errors."
        }
    }
}
