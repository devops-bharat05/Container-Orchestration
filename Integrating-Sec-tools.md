Integrating these tools into Jenkins allows you to automate security and quality scans as part of your CI/CD pipeline. Below is a detailed guide to integrating each tool:

---

### 1. **Integrating OWASP ZAP (Zed Attack Proxy)**

**Purpose:** OWASP ZAP is used for dynamic application security testing (DAST).

#### Steps to Integrate:
1. **Install the OWASP ZAP Plugin in Jenkins:**
   - Navigate to **Manage Jenkins > Plugins > Available**.
   - Search for `OWASP ZAP` and install it.

2. **Run ZAP in Docker:**
   ```bash
   docker run -p 8080:8080 -d zaproxy/zap-stable
   ```

3. **Configure Jenkins Pipeline:**
   - Add a stage to your Jenkins pipeline to execute ZAP security tests. Example:
     ```groovy
     pipeline {
         agent any
         stages {
             stage('Run ZAP') {
                 steps {
                     sh '''
                     docker run -p 8080:8080 -d zaproxy/zap-stable
                     zap-cli start
                     zap-cli open-url http://<your-application-url>
                     zap-cli quick-scan http://<your-application-url>
                     zap-cli report -o zap-report.html -f html
                     '''
                 }
             }
         }
     }
     ```

4. **Publish Reports:**
   - Use the **HTML Publisher Plugin** in Jenkins to publish `zap-report.html`.

---

### 2. **Integrating Trivy**

**Purpose:** Trivy is used for container image vulnerability scanning.

#### Steps to Integrate:
1. **Run Trivy in Docker:**
   ```bash
   docker run -v /var/run/docker.sock:/var/run/docker.sock -it aquasec/trivy <image-name>
   ```

2. **Install Trivy CLI on Jenkins (Recommended):**
   - SSH into the Jenkins server and install Trivy:
     ```bash
     wget https://github.com/aquasecurity/trivy/releases/latest/download/trivy_0.44.0_Linux-64bit.tar.gz
     tar zxvf trivy_0.44.0_Linux-64bit.tar.gz
     sudo mv trivy /usr/local/bin/
     ```

3. **Configure Jenkins Pipeline:**
   - Add a stage to your Jenkins pipeline for Trivy scanning:
     ```groovy
     pipeline {
         agent any
         stages {
             stage('Trivy Scan') {
                 steps {
                     sh '''
                     trivy image <image-name> > trivy-report.txt
                     '''
                 }
             }
         }
     }
     ```

4. **Publish Reports:**
   - Use the **Warnings Next Generation Plugin** to publish Trivy reports.

---

### 3. **Integrating OWASP Dependency-Check**

**Purpose:** Dependency-Check identifies vulnerable dependencies in your project.

#### Steps to Integrate:
1. **Install Dependency-Check Plugin in Jenkins:**
   - Navigate to **Manage Jenkins > Plugins > Available**.
   - Search for `OWASP Dependency-Check` and install it.

2. **Run Dependency-Check CLI in Jenkins Pipeline:**
   - Add a stage to your pipeline:
     ```groovy
     pipeline {
         agent any
         stages {
             stage('Dependency Check') {
                 steps {
                     sh '''
                     mkdir dependency-check
                     docker run --rm -v $(pwd)/dependency-check:/src owasp/dependency-check:latest --scan /src
                     '''
                 }
             }
         }
     }
     ```

3. **Publish Reports:**
   - Use the **OWASP Dependency-Check Plugin** to automatically parse and publish reports.

---

### 4. **Integrating SonarQube**

**Purpose:** SonarQube is used for code quality and security analysis.

#### Steps to Integrate:
1. **Install SonarQube Server:**
   - Run SonarQube in Docker:
     ```bash
     docker run -p 9000:9000 -d sonarqube
     ```

2. **Configure Jenkins for SonarQube:**
   - Go to **Manage Jenkins > Configure System > SonarQube Servers**.
   - Add a new server with:
     - Name: `SonarQube`
     - Server URL: `http://<SonarQube-Server-IP>:9000`
     - Authentication Token: Create in SonarQube under **My Account > Security > Tokens**.

3. **Install the SonarQube Scanner Plugin:**
   - Navigate to **Manage Jenkins > Plugins > Available**.
   - Search for `SonarQube Scanner` and install it.

4. **Configure Jenkins Pipeline:**
   - Add a stage to execute SonarQube analysis:
     ```groovy
     pipeline {
         agent any
         environment {
             SONARQUBE_SCANNER_HOME = tool 'SonarQubeScanner'
         }
         stages {
             stage('SonarQube Analysis') {
                 steps {
                     sh '''
                     sonar-scanner \
                         -Dsonar.projectKey=<project-key> \
                         -Dsonar.sources=. \
                         -Dsonar.host.url=http://<SonarQube-Server-IP>:9000 \
                         -Dsonar.login=<token>
                     '''
                 }
             }
         }
     }
     ```

---

### Complete Pipeline Example:
Here’s how a complete Jenkins pipeline might look:

```groovy
pipeline {
    agent any
    environment {
        SONARQUBE_SCANNER_HOME = tool 'SonarQubeScanner'
    }
    stages {
        stage('OWASP ZAP') {
            steps {
                sh '''
                docker run -p 8080:8080 -d zaproxy/zap-stable
                zap-cli start
                zap-cli open-url http://<your-application-url>
                zap-cli quick-scan http://<your-application-url>
                zap-cli report -o zap-report.html -f html
                '''
            }
        }
        stage('Trivy Scan') {
            steps {
                sh 'trivy image <image-name> > trivy-report.txt'
            }
        }
        stage('Dependency Check') {
            steps {
                sh '''
                mkdir dependency-check
                docker run --rm -v $(pwd)/dependency-check:/src owasp/dependency-check:latest --scan /src
                '''
            }
        }
        stage('SonarQube Analysis') {
            steps {
                sh '''
                sonar-scanner \
                    -Dsonar.projectKey=<project-key> \
                    -Dsonar.sources=. \
                    -Dsonar.host.url=http://<SonarQube-Server-IP>:9000 \
                    -Dsonar.login=<token>
                '''
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: '**/*.html, **/*.txt', allowEmptyArchive: true
            publishHTML(target: [
                reportDir: '.', reportFiles: 'zap-report.html', reportName: 'ZAP Report'
            ])
        }
    }
}
```

---

### Summary:
1. **Install plugins for each tool as required.**
2. **Run the tools in Docker or CLI within pipeline stages.**
3. **Use reporting plugins to publish and visualize results.**

Would you like further assistance with specific steps?
