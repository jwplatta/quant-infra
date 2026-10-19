CREATE DATABASE tractatus;
CREATE USER tractatus_user WITH PASSWORD 'tractatus';
GRANT ALL PRIVILEGES ON DATABASE tractatus TO tractatus_user;
\c tractatus
GRANT ALL ON SCHEMA public TO tractatus_user;
