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
CREATE USER tickrake_user;
GRANT ALL PRIVILEGES ON DATABASE tickrake TO tickrake_user;
\c tickrake
GRANT ALL ON SCHEMA public TO tickrake_user;

\getenv tickrake_password TICKRAKE_DB_PASSWORD
SELECT :'tickrake_password' <> '' AS tickrake_password_configured \gset
\if :tickrake_password_configured
  ALTER ROLE tickrake_user WITH LOGIN PASSWORD :'tickrake_password';
\else
  \echo 'TICKRAKE_DB_PASSWORD must be set before initializing PostgreSQL.'
  \quit 1
\endif
