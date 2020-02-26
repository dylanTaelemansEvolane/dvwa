def label = "docker-${UUID.randomUUID().toString()}"

podTemplate(label: label, yaml: """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: docker
    image: docker:1.11
    securityContext:
        privileged: true
    command: ['cat']
    tty: true
    volumeMounts:
    - name: dockersock
      mountPath: /var/run/docker.sock
  volumes:
  - name: dockersock
    hostPath:
      path: /var/run/docker.sock
"""
  ) {

  def image = "dylantaelemans/evolanenextlevel"
  node(label) {
    stage('Build Docker image') {
      git 'https://github.com/dylanTaelemansEvolane/dvwa.git'
      container('docker') {
        sh "docker build -t ${image} ."
      }
    }
    stage('docker vulnerability scanner') {
      container('docker') {
      sh '''apk add --update curl
            VERSION=$(
                curl --silent "https://api.github.com/repos/aquasecurity/trivy/releases/latest" | \\
                grep \'"tag_name":\' | \\
                sed -E \'s/.*"v([^"]+)".*/\\1/\'
            )

            wget https://github.com/aquasecurity/trivy/releases/download/v${VERSION}/trivy_${VERSION}_Linux-64bit.tar.gz
            tar zxvf trivy_${VERSION}_Linux-64bit.tar.gz
            mv trivy /usr/local/bin
            trivy --version
            trivy -s MEDIUM,HIGH,CRITICAL --exit-code 1 dylantaelemans/evolanenextlevel'''
      }
    }
    stage('Deploy Image') {
      container('docker') {
        withDockerRegistry(credentialsId: 'dockerhub', url: '') {
          sh "docker push ${image}:latest"
        }
      }
    }
  }
}
