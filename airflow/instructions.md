Running Airflow:
For Development (Quick Start):
bash# Terminal 1 - Webserver
source ~/airflow-env.sh
airflow webserver --port 8080

# Terminal 2 - Scheduler  
source ~/airflow-env.sh
airflow scheduler
For Production (Systemd Services):
bashsudo systemctl start airflow-webserver
sudo systemctl start airflow-scheduler
Access the Web UI:

Open http://localhost:8080 in your browser
Login with username: admin, password: admin OR change withn the script

