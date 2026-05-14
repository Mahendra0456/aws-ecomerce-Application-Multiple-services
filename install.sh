#!/bin/bash

echo "======================================="
echo " STARTING ENTERPRISE DEPLOYMENT "
echo "======================================="

############################################
# SYSTEM UPDATE
############################################

sudo yum update -y

############################################
# INSTALL REQUIRED PACKAGES
############################################

sudo yum install -y \
git \
python3 \
python3-pip \
nginx \
mariadb105

############################################
# START NGINX
############################################

sudo systemctl enable nginx
sudo systemctl start nginx

############################################
# CLONE GITHUB REPOSITORY
############################################

cd /home/ec2-user

if [ ! -d "aws-ecomerce-Application-Multiple-services" ]; then
    git clone https://github.com/Mahendra0456/aws-ecomerce-Application-Multiple-services.git
fi

############################################
# FRONTEND DEPLOYMENT
############################################

cd /home/ec2-user/aws-ecomerce-Application-Multiple-services/frontend

sudo cp -r * /usr/share/nginx/html/
sudo cp -r main/* /usr/share/nginx/html/

############################################
# BACKEND SETUP
############################################

cd /home/ec2-user/aws-ecomerce-Application-Multiple-services/backend

python3 -m venv venv

source venv/bin/activate

############################################
# INSTALL PYTHON REQUIREMENTS
############################################

pip install --upgrade pip

pip install -r requirements.txt

pip install gunicorn

############################################
# CREATE ENV FILE
############################################

cat > .env <<EOF
PORT=5000
FLASK_DEBUG=false

DB_HOST=ecommerce-db-1.c9uouey2ais1.ap-south-1.rds.amazonaws.com
DB_USER=admin
DB_PASSWORD=Root123456
DB_NAME=ecommerce-db-1

MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=veeraopstechnologies@gmail.com
MAIL_PASSWORD=lfat oilp ikac siza
EOF

############################################
# IMPORT DATABASE
############################################

mysql -h ecommerce-db-1.c9uouey2ais1.ap-south-1.rds.amazonaws.com \
-u admin \
-pRoot123456 \
cloud < test.sql

############################################
# CREATE GUNICORN SYSTEMD SERVICE
############################################

sudo tee /etc/systemd/system/flaskapp.service > /dev/null <<EOF
[Unit]
Description=Flask Gunicorn Service
After=network.target

[Service]
User=root
WorkingDirectory=/home/ec2-user/aws-ecomerce-Application-Multiple-services/backend
ExecStart=/home/ec2-user/aws-ecomerce-Application-Multiple-services/backend/venv/bin/gunicorn -w 4 -b 0.0.0.0:5000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

############################################
# START FLASK SERVICE
############################################

sudo systemctl daemon-reload

sudo systemctl enable flaskapp

sudo systemctl restart flaskapp

############################################
# CREATE NGINX CONFIG
############################################

sudo tee /etc/nginx/conf.d/google-store.conf > /dev/null <<EOF
server {

    listen 80;

    server_name _;

    root /usr/share/nginx/html;

    index index.html;

    location /api/ {

        proxy_pass http://10.0.175.247:5000/api/;

        proxy_http_version 1.1;

        proxy_set_header Host \$host;

        proxy_set_header X-Real-IP \$remote_addr;

        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location / {

        try_files \$uri \$uri/ /index.html;
    }
}
EOF

############################################
# REMOVE DEFAULT NGINX CONFIG
############################################

sudo rm -f /etc/nginx/conf.d/default.conf

############################################
# RESTART NGINX
############################################

sudo nginx -t

sudo systemctl restart nginx

############################################
# SHOW STATUS
############################################

echo "======================================="
echo " NGINX STATUS "
echo "======================================="

sudo systemctl status nginx --no-pager

echo "======================================="
echo " FLASK STATUS "
echo "======================================="

sudo systemctl status flaskapp --no-pager

echo "======================================="
echo " DEPLOYMENT COMPLETED "
echo "======================================="
