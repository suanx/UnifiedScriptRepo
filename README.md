UnifiedScriptRepo
-----------------

This repository contains multiple Bash scripts for automating DevOps and environment setup tasks.

Current Script: bootstrap.sh
----------------------------

This script installs and configures the following tools on a Debian-based system:

- Jenkins
- Docker
- MicroK8s
- SonarQube

How to Use:
-----------

1. Clone the repository:
   git clone https://github.com/yourusername/UnifiedScriptRepo.git
   cd UnifiedScriptRepo

2. Make the script executable:
   chmod +x bootstrap.sh

3. Run the script with root privileges:
   sudo ./bootstrap.sh

After completion, access the services:
---------------------------------------

- Jenkins UI: http://<your-server-ip>:8080
- SonarQube UI: http://<your-server-ip>:9000
- MicroK8s Kubernetes CLI via alias: kubectl

Notes:
------

- You may need to log out and back in (or restart your shell) to apply group changes for Docker and MicroK8s.
- The Jenkins initial admin password will be shown at the end of the script.
- SonarQube may take a few minutes to fully start.

Planned Scripts (Coming Soon):
------------------------------

- Kubernetes deployment automation
- Terraform infrastructure provisioning
- Docker image build and push helpers
- Monitoring and logging setup scripts

Contribution:
-------------

Contributions, issues, and feature requests are welcome. Please open a pull request or submit an issue.

License:
--------

MIT License

Contact:
--------

Your Name - sks.awsdev"gmail.com  
Project Link: https://github.com/suanx/UnifiedScriptRepo
