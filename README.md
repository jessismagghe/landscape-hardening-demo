# Landscape Hardening Demo

Jessi Smagghe - Berlin 2025 Commercial Sprint

"Automating CIS and DISA-STIG compliance with Landscape"
* [Presentation Slides](https://docs.google.com/presentation/d/1Sn_f6Q80TL4gz_brUtvI9Hdpaav-lhHi6MFV5snZ5f8/edit?usp=sharing)
* [Acronym Guide](./reference.md#acronym-guide)
* [Presentation Links](./reference.md#presentation-links)

# Overview
This demo will provide you a testing environment to explore methods of automating compliance and system hardening in Landscape. The setup will:

1. Deploy a [25.04 Landscape Server](https://documentation.ubuntu.com/landscape/reference/release-notes/25.04-release-notes/)
2. Deploy an Ubuntu 24.04 client container
3. Configure client with:
    - Ubuntu Pro
    - Ubuntu Security Guide
    - [Security Profiles Landscape Plugin](https://documentation.ubuntu.com/landscape/how-to-guides/web-portal/web-portal-24-04-or-later/use-security-profiles/)
4. Enroll client with your Landscape server


# Deploying The Demo
### Part Zero: Prerequisites  
1. You must have **LXD** installed and initialized with a **default profile** and storage pool

### Part One: Deploy the Landscape Server
1. Clone the repo: `git clone https://github.com/jessismagghe/landscape-hardening-demo.git`
2. Run the deployment script: `./landscape-deploy-demo.sh`
3. Enter your [Ubuntu Pro Token](https://ubuntu.com/pro/dashboard) when prompted.

### Part Two: Configure Landscape and Deploy Clients
_When the Landscape Server deployment is complete the script **WILL PAUSE** and Landscape UI will open in a new browser window. To allow you to **create an admin account.**_

1. Enter your credentials to create a Landscape admin account.
2. Return to your terminal and enter `yes` to continue the script. 

# Tearing Down The Demo
You can chose to run the automatic teardown script `./landscape-teardown-demo.sh` or preform the following manual steps in the LXD UI:

1. Navigate to the `Landscape-Demo-25-04` LXD project.
2. Navigate to the `Instances` tab. "Stop" and "Delete" all containers.
3. Navigate to the `Images` tab. Select all images and "Delete."
4. Navigate to the `Configuration` tab and "Delete Project"

