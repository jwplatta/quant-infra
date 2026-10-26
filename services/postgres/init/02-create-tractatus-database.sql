DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'tractatus_user') THEN
    CREATE ROLE tractatus_user LOGIN PASSWORD 'tractatus';
  ELSE
    ALTER ROLE tractatus_user WITH LOGIN PASSWORD 'tractatus';
  END IF;
END
$$;

SELECT 'CREATE DATABASE tractatus OWNER tractatus_user'
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'tractatus')
\gexec

GRANT ALL PRIVILEGES ON DATABASE tractatus TO tractatus_user;
\connect tractatus
GRANT ALL ON SCHEMA public TO tractatus_user;
