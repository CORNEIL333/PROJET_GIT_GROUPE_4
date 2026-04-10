# 🖥️ Installation du Serveur Git

## Prérequis
- Ubuntu 20.04+ ou Debian 11+
- 2 Go RAM minimum
- 20 Go espace disque

## Option 1 : Gitea (recommandé)
```bash
wget -O /usr/local/bin/gitea https://dl.gitea.io/gitea/latest/gitea-linux-amd64
chmod +x /usr/local/bin/gitea
adduser --system --shell /bin/bash --group --disabled-password --home /home/git git
gitea web --port 3000
```

## Option 2 : GitLab CE
```bash
apt update && apt install -y curl openssh-server ca-certificates
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | bash
EXTERNAL_URL="http://git.votre-universite.cm" apt install gitlab-ce
```

## Option 3 : Git simple (SSH)
```bash
adduser git
sudo -u git git init --bare /home/git/repos/cours-info101.git
```
