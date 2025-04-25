pipeline {
    agent any

    environment {
        AZURE_CREDENTIALS_FILE = credentials('AZURE_CREDENTIALS_FILE') 
    }

    stages {
        stage('Préparation') {
            steps {
                checkout scm
            }
        }
        stage('Login to Azure') {
            steps {
                script {
                    sh 'echo Authenticating with Azure...'
                    sh '''
                    # Extraire les valeurs depuis le fichier JSON
                    export AZURE_CREDENTIALS=$(cat $AZURE_CREDENTIALS_FILE)
                    export AZURE_CLIENT_ID=$(echo $AZURE_CREDENTIALS | jq -r .clientId)
                    export AZURE_CLIENT_SECRET=$(echo $AZURE_CREDENTIALS | jq -r .clientSecret)
                    export AZURE_TENANT_ID=$(echo $AZURE_CREDENTIALS | jq -r .tenantId)
                    export AZURE_SUBSCRIPTION_ID=$(echo $AZURE_CREDENTIALS | jq -r .subscriptionId)

                    # Se connecter à Azure avec le Service Principal
                    az login --service-principal \
                      -u $AZURE_CLIENT_ID \
                      -p $AZURE_CLIENT_SECRET \
                      --tenant $AZURE_TENANT_ID
                    
                    # Assigner la subscription
                    az account set --subscription $AZURE_SUBSCRIPTION_ID

                    # Vérifier la connexion
                    az account show
                    '''
                }
            }
        }

        stage('Terraform Init') {
            steps {
                dir('/terraform') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('/terraform') {
                    sh 'terraform plan'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('/terraform') {
                    sh 'terraform apply -auto-approve'
                }
            }
        }
        stage('Deploy with Ansible') {
            steps {
                sh 'ansible-playbook -i ansible/inventory.ini   ansible/playbook.yml'
            }
        }

    }

    post {
        always {
            echo 'Cleaning up...'
            sh 'az logout'
        }
    }
}
