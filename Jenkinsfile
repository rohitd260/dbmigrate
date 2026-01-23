pipeline {
    agent any

    options {
        disableConcurrentBuilds()
    }

    environment {
        DB_HOST     = credentials('flyway-db-url')
        DB_USER     = credentials('flyway-db-user')
        DB_PASSWORD = credentials('flyway-db-password')
        DB_NAME     = credentials('flyway-db-name')
        DB_PORT     = credentials('flyway-db-port')
        MAVEN_VERSION = '3.9.6'
        MAVEN_HOME    = "${WORKSPACE}/apache-maven-${MAVEN_VERSION}"
        PATH          = "${MAVEN_HOME}/bin:${env.PATH}"
        MIG_DIR = 'src/main/resources/db/migration'
        ECS_CLUSTER = "${env.ORGANISATION}-${env.ENVIRONMENT}-${env.REGION}-ecs-cluster"
    }
    
    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Initialize ECS Daemon Services') {
            steps {
              sh 'echo "Daemon initialized"'
            }
        }

        stage('Detect Migration Changes') {
            steps {
                script {
                    def migrationDetected = sh(
                        script: '''
                            set +e
                            
                            # Get current branch name from Jenkins environment or git
                            if [ -n "$GIT_BRANCH" ]; then
                                CURRENT_BRANCH=$(echo $GIT_BRANCH | sed 's|origin/||')
                            else
                                CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --abbrev-ref HEAD)
                            fi
                            
                            echo "Current branch: $CURRENT_BRANCH" >&2
                            
                            if [ -d "$MIG_DIR" ]; then
                                # Check for migration changes in the last commit
                                if git diff --name-only HEAD~1 HEAD 2>/dev/null | grep -q "^$MIG_DIR/"; then
                                    echo "DB migration changes detected" >&2
                                    echo "true"
                                else
                                    echo "No DB migration changes detected" >&2
                                    echo "false"
                                fi
                            else
                                echo "Migration directory not found, skipping detection" >&2
                                echo "false"
                            fi
                        ''',
                        returnStdout: true
                    ).trim()
                    
                    env.DETECT_MIGRATION = migrationDetected
                    echo "DETECT_MIGRATION set to: ${env.DETECT_MIGRATION}"
                }
            }
        }

        stage('Install Maven') {
            steps {
                script {
                    echo "Installing Maven..."
                    sh '''
                        set -e
                        if [ ! -d "$MAVEN_HOME" ]; then
                            echo "Installing Maven..."
                            wget -q https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
                            tar -xzf apache-maven-${MAVEN_VERSION}-bin.tar.gz
                        fi
                        mvn -version
                    '''
                }
            }
        }

        stage('Stopping ECS Daemon Service...') {
            when {
                expression { env.DETECT_MIGRATION == 'true' }
            }
            steps {
                script {
                    echo 'Stopping the ECS Daemon Services....!!'
                    echo "Waiting 5 seconds for services to stop..."
                    sleep(time: 5, unit: 'SECONDS')
                }
            }
        }

        stage('Flyway Validate') {
            steps {
                sh '''
                    set -e
                    DB_URL="jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}"
                    mvn -B flyway:validate \
                        -Dflyway.url=$DB_URL \
                        -Dflyway.user=$DB_USER \
                        -Dflyway.password=$DB_PASSWORD \
                        -Dflyway.ignoreMigrationPatterns="*:pending" \
                        -Dflyway.schemas=public
                '''
            }
        }

        stage('Flyway Migrate') {
            steps {
                sh '''
                    set -e
                    DB_URL="jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}"
                    mvn -B flyway:migrate \
                        -Dflyway.url=$DB_URL \
                        -Dflyway.user=$DB_USER \
                        -Dflyway.password=$DB_PASSWORD \
                        -Dflyway.schemas=public
                '''
                echo "Waiting 10 seconds for settling the migration..."
                sleep(time: 10, unit: 'SECONDS')
            }
        }

        stage('Starting ECS Daemon Service...') {
            when {
                expression { env.DETECT_MIGRATION == 'true' }
            }
            steps {
                script {
                    echo 'Starting the ECS Daemon Services....!!'
                    echo "Waiting 5 seconds for services to start..."
                    sleep(time: 5, unit: 'SECONDS')
                }
            }
        }
    }

    post {
        success {
            echo 'Database migration completed successfully'
        }
        failure {
            echo 'Database migration failed'
        }
        always {
            deleteDir()
        }
    }
}
