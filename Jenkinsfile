pipeline {
agent any

stages {
    stage('Checkout') {
        steps {
            git branch: 'main', 'url: https://github.com/chaitramk23/shopping-cart.git'
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
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
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
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
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
                 // Capture the Terraform output (public IP)
                def ip = sh(script: "cd terraform-infra && terraform output -raw instance_ip", returnStdout: true).trim()
                writeFile file: 'ansible/inventory.ini', text: "[app]\n${ip} ansible_user=ec2-user"
                echo "Inventory created with IP: ${ip}" 
            }
        }
    }

    stage('Ansible Deploy') {
        steps {
            dir('ansible') {
                sh '''
                     set -e
                       echo "[INFO] Running Ansible playbook..."
                       export ANSIBLE_HOST_KEY_CHECKING=False
                       ansible-playbook -i inventory.ini playbook.yml --private-key=/var/lib/jenkins/.ssh/jenkins_key.pem
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
