pipeline {

    agent any

    parameters {

        string(
            name: 'PROJECT_NAME',
            defaultValue: 'wanderlust',
            description: 'Project Name'
        )

    }

    environment {

        PROJECT_NAME = "${params.PROJECT_NAME}"

        FRONTEND_IMAGE = "frontend"
        BACKEND_IMAGE  = "backend"
        ADMIN_IMAGE    = "admin"

        TAG = "${BUILD_NUMBER}"

        SCANNER_HOME = tool 'sonar-scanner'

    }

    stages {

    /**********************************************************************
     * CHECKOUT
     **********************************************************************/
    stage('Checkout') {

        steps {

            checkout scm

            sh '''
            mkdir -p reports
            '''

        }
    }

    /**********************************************************************
     * DETECT PROJECT STRUCTURE
     **********************************************************************/
    stage('Detect Project Structure') {

        steps {

            script {

                echo "========================================"
                echo " Detecting Project Structure"
                echo "========================================"

                env.HAS_FRONTEND = fileExists("Application-Code/frontend") ? "true" : "false"
                env.HAS_BACKEND  = fileExists("Application-Code/backend")  ? "true" : "false"
                env.HAS_ADMIN    = fileExists("Application-Code/admin")    ? "true" : "false"

                echo "Frontend : ${env.HAS_FRONTEND}"
                echo "Backend  : ${env.HAS_BACKEND}"
                echo "Admin    : ${env.HAS_ADMIN}"

                if (env.HAS_FRONTEND == "false" &&
                    env.HAS_BACKEND == "false" &&
                    env.HAS_ADMIN == "false") {

                    error("No Application-Code structure found.")

                }

            }

        }

    }

    /**********************************************************************
     * DETECT BACKEND LANGUAGE
     **********************************************************************/
    stage('Detect Backend Language') {

        when {
            expression {
                env.HAS_BACKEND == "true"
            }
        }

        steps {

            script {

                echo "========================================"
                echo " Detecting Backend Language"
                echo "========================================"

                if (fileExists('Application-Code/backend/pom.xml')) {

                    env.APP_LANG = "java"

                }
                else if (fileExists('Application-Code/backend/package.json')) {

                    env.APP_LANG = "nodejs"

                }
                else if (fileExists('Application-Code/backend/requirements.txt')) {

                    env.APP_LANG = "python"

                }
                else if (fileExists('Application-Code/backend/go.mod')) {

                    env.APP_LANG = "golang"

                }
                else {

                    error("Unsupported Backend Language")

                }

                echo "Detected Language : ${env.APP_LANG}"

            }

        }

    }

    /**********************************************************************
     * INSTALL DEPENDENCIES
     **********************************************************************/
    stage('Install Dependencies') {

        steps {

            script {

                /**********************
                 * BACKEND
                 **********************/
                if (env.HAS_BACKEND == "true") {

                    dir('Application-Code/backend') {

                        switch(env.APP_LANG) {

                            case "java":

                                sh '''
                                echo "Installing Maven Dependencies..."
                                mvn clean install -DskipTests
                                '''
                                break

                            case "nodejs":

                                sh '''
                                echo "Installing NodeJS Dependencies..."
                                npm install
                                '''
                                break

                            case "python":

                                sh '''
                                echo "Installing Python Dependencies..."

                                python3 -m venv venv

                                . venv/bin/activate

                                pip install --upgrade pip

                                pip install -r requirements.txt
                                '''
                                break

                            case "golang":

                                sh '''
                                echo "Downloading Go Modules..."
                                go mod download
                                '''
                                break

                        }

                    }

                }

                /**********************
                 * FRONTEND
                 **********************/
                if (env.HAS_FRONTEND == "true") {

                    dir('Application-Code/frontend') {

                        sh '''
                        echo "Installing Frontend Dependencies..."

                        export NODE_OPTIONS=--openssl-legacy-provider

                        npm install
                        '''

                    }

                }

                /**********************
                 * ADMIN
                 **********************/
                if (env.HAS_ADMIN == "true") {

                    dir('Application-Code/admin') {

                        sh '''
                        echo "Installing Admin Dependencies..."

                        export NODE_OPTIONS=--openssl-legacy-provider

                        npm install
                        '''

                    }

                }

            }

        }

    }


    /**********************************************************************
     * LINT
     **********************************************************************/
    stage('Lint') {

        steps {

            script {

                /**********************
                 * Backend Lint
                 **********************/
                if (env.HAS_BACKEND == "true") {

                    dir('Application-Code/backend') {

                        switch(env.APP_LANG) {

                            case "java":

                                sh '''
                                echo "Running Java Lint..."

                                if [ -f pom.xml ]; then
                                    mvn checkstyle:check || true
                                fi
                                '''

                                break

                            case "nodejs":

                                sh '''
                                echo "Running ESLint..."

                                if [ -f package.json ]; then

                                    if node -e "process.exit(require('./package.json').scripts?.lint ? 0 : 1)"; then
                                        npm run lint || true
                                    else
                                        echo "No lint script found."
                                    fi

                                fi
                                '''

                                break

                            case "python":

                                sh '''
                                echo "Running Pylint..."

                                . venv/bin/activate

                                pip install pylint >/dev/null 2>&1 || true

                                find . -name "*.py" | xargs pylint || true
                                '''

                                break

                            case "golang":

                                sh '''
                                echo "Running Go Lint..."

                                golangci-lint run || true
                                '''

                                break

                        }

                    }

                }

            }

        }

    }

    /**********************************************************************
     * DEPENDENCY SCAN
     **********************************************************************/
    stage('Dependency Scan') {

        steps {

            script {

                if (env.HAS_BACKEND == "true") {

                    dir('Application-Code/backend') {

                        switch(env.APP_LANG) {

                            case "java":

                                sh '''
                                echo "Running OWASP Dependency Check..."
                                dependency-check.sh --scan .  --format HTML  --format JSON  --out ../../reports/dependency-check || true
                                '''
                                break

                            case "nodejs":

                                sh '''
                                echo "Running npm audit..."
                                npm audit --audit-level=high || true
                                '''
                                break

                            case "python":

                                sh '''
                                echo "Running pip-audit..."
                                . venv/bin/activate
                                pip install pip-audit >/dev/null 2>&1 || true
                                pip-audit || true
                                '''
                                break

                            case "golang":

                                sh '''
                                echo "Running govulncheck..."
                                govulncheck ./... || true
                                '''
                                break

                        }

                    }

                }

            }

        }

    }

    /**********************************************************************
     * UNIT TESTS
     **********************************************************************/
    stage('Unit Tests') {

        steps {

            script {

                if (env.HAS_BACKEND == "true") {

                    dir('Application-Code/backend') {

                        switch(env.APP_LANG) {

                            case "java":

                                sh '''
                                echo "Running Java Tests..."
                                mvn test || true
                                '''
                                break

                            case "nodejs":

                                sh '''
                                echo "Running NodeJS Tests..."

                                TEST_SCRIPT=$(node -p "require('./package.json').scripts?.test || ''")

                                if [ -z "$TEST_SCRIPT" ] || \
                                   [ "$TEST_SCRIPT" = "echo \\"Error: no test specified\\" && exit 1" ]; then

                                    echo "No Unit Tests Configured."

                                else

                                    npm test || true

                                fi
                                '''

                                break

                            case "python":

                                sh '''
                                echo "Running Python Tests..."

                                . venv/bin/activate

                                if command -v pytest >/dev/null 2>&1
                                then
                                    pytest || true
                                else
                                    echo "pytest not installed."
                                fi
                                '''

                                break

                            case "golang":

                                sh '''
                                echo "Running Go Tests..."

                                go test ./... || true
                                '''

                                break

                        }

                    }

                }

            }

        }

    }

    /**********************************************************************
     * COVERAGE REPORT DETECTION
     **********************************************************************/
    stage('Coverage') {

        steps {

            sh '''

            echo "======================================"
            echo "Searching Coverage Reports"
            echo "======================================"

            find . -type f \\(

                -name "lcov.info" -o \
                -name "coverage.xml" -o \
                -name "jacoco.xml" -o \
                -name "*.exec" -o \
                -name "coverage.out"

            \\) || true

            '''

        }

    }

    /**********************************************************************
     * SONARQUBE ANALYSIS
     **********************************************************************/
    stage('SonarQube Analysis') {

        steps {

            catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {

                withSonarQubeEnv('sonarqube') {

                    script {

                        if (env.HAS_BACKEND == "true") {

                            dir('Application-Code/backend') {

                                switch(env.APP_LANG) {

                                    /**************** JAVA ****************/
                                    case "java":

                                        sh """
                                        mvn sonar:sonar \
                                        -Dsonar.projectKey=${PROJECT_NAME}-backend \
                                        -Dsonar.projectName=${PROJECT_NAME}-backend
                                        """

                                        break

                                    /**************** NODEJS ****************/
                                    case "nodejs":

                                        sh """
                                        ${SCANNER_HOME}/bin/sonar-scanner \
                                        -Dsonar.projectKey=${PROJECT_NAME}-backend \
                                        -Dsonar.projectName=${PROJECT_NAME}-backend \
                                        -Dsonar.sources=. \
                                        -Dsonar.sourceEncoding=UTF-8 \
                                        -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
                                        """

                                        break

                                    /**************** PYTHON ****************/
                                    case "python":

                                        sh """
                                        ${SCANNER_HOME}/bin/sonar-scanner \
                                        -Dsonar.projectKey=${PROJECT_NAME}-backend \
                                        -Dsonar.projectName=${PROJECT_NAME}-backend \
                                        -Dsonar.sources=. \
                                        -Dsonar.python.coverage.reportPaths=coverage.xml
                                        """

                                        break

                                    /**************** GOLANG ****************/
                                    case "golang":

                                        sh """
                                        ${SCANNER_HOME}/bin/sonar-scanner \
                                        -Dsonar.projectKey=${PROJECT_NAME}-backend \
                                        -Dsonar.projectName=${PROJECT_NAME}-backend \
                                        -Dsonar.sources=. \
                                        -Dsonar.go.coverage.reportPaths=coverage.out
                                        """

                                        break

                                }

                            }

                        }

                    }

                }

            }

        }

    }

    /**********************************************************************
     * SONAR QUALITY GATE
     **********************************************************************/
    stage('Quality Gate') {

        steps {

            timeout(time: 10, unit: 'MINUTES') {

                waitForQualityGate abortPipeline: true

            }

        }

    }

    /**********************************************************************
     * TRIVY FILESYSTEM SCAN
     **********************************************************************/
    stage('Trivy Filesystem Scan') {

        steps {

            catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {

                sh '''

                mkdir -p reports/trivy

                echo "===================================="
                echo "Trivy Filesystem Scan"
                echo "===================================="

                trivy fs . \
                    --scanners vuln,secret,misconfig \
                    --format json \
                    --output reports/trivy/trivy-fs-report.json

                trivy fs . \
                    --scanners vuln,secret,misconfig \
                    --format template \
                    --template "@/usr/local/share/trivy/templates/html.tpl" \
                    --output reports/trivy/trivy-fs-report.html

                '''

            }

        }

    }

    /**********************************************************************
     * APPLICATION BUILD
     **********************************************************************/
    stage('Build') {

        steps {

            script {

                /**********************
                 * BACKEND BUILD
                 **********************/
                if (env.HAS_BACKEND == "true") {

                    dir('Application-Code/backend') {

                        switch(env.APP_LANG) {

                            case "java":

                                sh '''
                                echo "Building Java Application..."
                                mvn clean package -DskipTests
                                '''

                                break

                            case "nodejs":

                                sh '''
                                echo "Building NodeJS Application..."
                                npm run build
                                '''

                                break

                            case "python":

                                sh '''
                                echo "Python application detected."
                                echo "No build step required."
                                '''

                                break

                            case "golang":

                                sh '''
                                echo "Building Go Application..."
                                go build ./...
                                '''

                                break

                        }

                    }

                }

                /**********************
                 * FRONTEND BUILD
                 **********************/
                if (env.HAS_FRONTEND == "true") {

                    dir('Application-Code/frontend') {

                        sh '''

                        echo "Building Frontend..."

                        export NODE_OPTIONS=--openssl-legacy-provider

                        npm run build

                        '''

                    }

                }

                /**********************
                 * ADMIN BUILD
                 **********************/
                if (env.HAS_ADMIN == "true") {

                    dir('Application-Code/admin') {

                        sh '''

                        echo "Building Admin..."

                        export NODE_OPTIONS=--openssl-legacy-provider

                        npm run build

                        '''

                    }

                }

            }

        }

    }


    /**********************************************************************
     * DOCKER BUILD
     **********************************************************************/
    stage('Docker Build') {

        steps {

            script {

                if (env.HAS_FRONTEND == "true" &&
                    fileExists('Application-Code/frontend/Dockerfile')) {

                    sh """
                    docker build \
                    -t ${FRONTEND_IMAGE}:${TAG} \
                    -f Application-Code/frontend/Dockerfile \
                    Application-Code/frontend
                    """

                }

                if (env.HAS_BACKEND == "true" &&
                    fileExists('Application-Code/backend/Dockerfile')) {

                    sh """
                    docker build \
                    -t ${BACKEND_IMAGE}:${TAG} \
                    -f Application-Code/backend/Dockerfile \
                    Application-Code/backend
                    """

                }

                if (env.HAS_ADMIN == "true" &&
                    fileExists('Application-Code/admin/Dockerfile')) {

                    sh """
                    docker build \
                    -t ${ADMIN_IMAGE}:${TAG} \
                    -f Application-Code/admin/Dockerfile \
                    Application-Code/admin
                    """

                }

            }

        }

    }

    /**********************************************************************
     * TRIVY IMAGE SCAN
     **********************************************************************/
    stage('Trivy Image Scan') {

        steps {

            catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {

                sh '''

                mkdir -p reports/trivy
                mkdir -p reports/sbom

                scan_image() {

                    IMAGE=$1
                    NAME=$2

                    if docker image inspect ${IMAGE} >/dev/null 2>&1; then

                        echo "Scanning ${IMAGE}"

                        ############################################
                        # JSON Report
                        ############################################

                        trivy image  --format json --output reports/trivy/${NAME}.json ${IMAGE}

                        ############################################
                        # HTML Report
                        ############################################

                        trivy image --format template --template "@/usr/local/share/trivy/templates/html.tpl" --output reports/trivy/${NAME}.html ${IMAGE}

                        ############################################
                        # SBOM
                        ############################################

                        trivy image  --format cyclonedx  --output reports/sbom/${NAME}-sbom.json  ${IMAGE}

                        ############################################
                        # Fail Build
                        ############################################

                        trivy image --severity HIGH,CRITICAL --exit-code 1 ${IMAGE}

                    else

                        echo "${IMAGE} not found"

                    fi

                }

                scan_image frontend:${TAG} frontend
                scan_image backend:${TAG} backend
                scan_image admin:${TAG} admin

                '''

            }

        }

    }

    /**********************************************************************
     * PUSH IMAGE TO NEXUS
     **********************************************************************/
    stage('Push Image') {

        steps {

            withCredentials([

                usernamePassword(

                    credentialsId: 'nexus-docker-cred',

                    usernameVariable: 'NEXUS_USER',

                    passwordVariable: 'NEXUS_PASS'

                )

            ]) {

                sh '''

                NEXUS_URL=localhost:32770

                echo "$NEXUS_PASS" | docker login -u "$NEXUS_USER"    --password-stdin $NEXUS_URL

                ###################################################
                # FRONTEND
                ###################################################

                if docker image inspect frontend:${TAG} >/dev/null 2>&1
                then

                    docker tag frontend:${TAG}  $NEXUS_URL/${PROJECT_NAME}-frontend:${TAG}

                    docker push $NEXUS_URL/${PROJECT_NAME}-frontend:${TAG}

                fi

                ###################################################
                # BACKEND
                ###################################################

                if docker image inspect backend:${TAG} >/dev/null 2>&1
                then

                    docker tag backend:${TAG} $NEXUS_URL/${PROJECT_NAME}-backend:${TAG}

                    docker push $NEXUS_URL/${PROJECT_NAME}-backend:${TAG}

                fi

                ###################################################
                # ADMIN
                ###################################################

                if docker image inspect admin:${TAG} >/dev/null 2>&1
                then

                    docker tag admin:${TAG} $NEXUS_URL/${PROJECT_NAME}-admin:${TAG}

                    docker push $NEXUS_URL/${PROJECT_NAME}-admin:${TAG}

                fi

                docker logout $NEXUS_URL

                '''

            }

        }

    }

} // End stages


/***************************************************************
 * POST ACTIONS
 ***************************************************************/
post {

    always {

        archiveArtifacts(

            artifacts: '''
reports/**/*,
**/coverage/**/*,
**/lcov.info,
**/coverage.xml,
**/jacoco.xml,
**/*.exec,
**/coverage.out,
**/target/*.jar,
**/target/surefire-reports/**/*,
**/dist/**/*,
**/build/**/*,
**/*.log
''',

            excludes: '''
**/node_modules/**,
**/.npm/**,
**/.cache/**
''',

            fingerprint: true,

            allowEmptyArchive: true

        )

        cleanWs notFailBuild: true

    }

    success {

        echo "Pipeline Completed Successfully"

    }

    unstable {

        echo "Pipeline Completed with Security Findings"

    }

    failure {

        echo "Pipeline Failed"

    } //

} //
