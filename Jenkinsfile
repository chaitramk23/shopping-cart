pipeline {
  agent any

  environment {
    INFRA_DIR = 'terraform-infra'
    ANSIBLE_DIR = 'ansible'
    APP_DIR = '.'           // root where pom.xml exists
    TF_VAR_env = 'dev'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build') {
      steps {
        dir("${APP_DIR}") {
          sh 'mvn -B clean package -DskipTests'  // adjust flags as needed
        }
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
              export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
              export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
              terraform init -input=false
              terraform plan -out=tfplan -input=false
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
              export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
              export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
              terraform apply -input=false -auto-approve tfplan
            '''
          }
        }
      }
    }

    stage('Prepare Ansible Inventory & Key') {
      steps {
        dir('terraform-infra') {
          // get the instance IP and ensure the key file exists in infra/
          sh '''
            INSTANCE_IP=$(terraform output -raw instance_public_ip)
            echo "[app]" > ../${ANSIBLE_DIR}/inventory.ini
            echo "${INSTANCE_IP} ansible_user=ec2-user" >> ../${ANSIBLE_DIR}/inventory.ini
            ls -l
            # jenkins_key.pem was created by local_file resource
            if [ -f jenkins_key.pem ]; then
              cp jenkins_key.pem ../${ANSIBLE_DIR}/jenkins_key.pem
              chmod 600 ../${ANSIBLE_DIR}/jenkins_key.pem
            else
              echo "WARNING: jenkins_key.pem not found in ${INFRA_DIR} - make sure terraform created it."
            fi
          '''
        }
      }
    }

    stage('Ansible Deploy') {
      steps {
        dir("${ANSIBLE_DIR}") {
          // Path to built WAR in workspace
          script {
            def war = sh(script: "ls ../${APP_DIR}/target/*.war | head -n1", returnStdout: true).trim()
            if (!war) {
              error "WAR artifact not found"
            }
            sh """
              ansible-playbook -i inventory.ini playbook.yml --private-key=jenkins_key.pem -u ec2-user -e app_war=${war}
            """
          }
        }
      }
    }
  }

  post {
    success {
      echo "Deployment pipeline finished successfully."
    }
    failure {
      echo "Pipeline failed."
    }
  }
}
