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

        // stage('Detect Migration Changes') {
        //     steps {
        //         script {
        //             def migrationDetected = false
                    
        //             // Get the changeset from Jenkins
        //             def changeLogSets = currentBuild.changeSets
                    
        //             echo "Checking for migration changes in changeset..."
                    
        //             for (changeSet in changeLogSets) {
        //                 for (entry in changeSet.items) {
        //                     for (file in entry.affectedFiles) {
        //                         def filePath = file.path
        //                         echo "Changed file: ${filePath}"
                                
        //                         if (filePath.startsWith(env.MIG_DIR + '/')) {
        //                             echo "DB migration changes detected in: ${filePath}"
        //                             migrationDetected = true
        //                             break
        //                         }
        //                     }
        //                     if (migrationDetected) break
        //                 }
        //                 if (migrationDetected) break
        //             }
                    
        //             if (!migrationDetected) {
        //                 echo "No DB migration changes detected"
        //             }
                    
        //             env.DETECT_MIGRATION = migrationDetected.toString()
        //             echo "DETECT_MIGRATION set to: ${env.DETECT_MIGRATION}"
        //         }
        //     }
        // }

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
                changeset "${MIG_DIR}/**"
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
                changeset "${MIG_DIR}/**"
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
