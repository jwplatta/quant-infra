CREATE DATABASE mlflow;
CREATE USER mlflow WITH PASSWORD 'mlflow';
GRANT ALL PRIVILEGES ON DATABASE mlflow TO mlflow;
\c mlflow
GRANT ALL ON SCHEMA public TO mlflow;

CREATE DATABASE grafana;
CREATE USER grafana WITH PASSWORD 'grafana';
GRANT ALL PRIVILEGES ON DATABASE grafana TO grafana;
\c grafana
GRANT ALL ON SCHEMA public TO grafana;

CREATE DATABASE tickrake;
CREATE USER tickrake_user WITH PASSWORD 'tickrake';
GRANT ALL PRIVILEGES ON DATABASE tickrake TO tickrake_user;
\c tickrake
GRANT ALL ON SCHEMA public TO tickrake_user;
