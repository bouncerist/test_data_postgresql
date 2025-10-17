# Launch PostgreSQL in Dbeaver
## Navigate to the docker-compose repository in the terminal.
## Up the containers

docker-compose up -d

## Open DBeaver and create a connection (select PostgreSQL)
### We enter the data that is specified in docker-compose (if you have changed them)
### If you haven't changed it, then use these:

  Database: postgres <br />
  Username: postgres_user <br />
  Password: postgres_password <br />
  Port: 5433

## SQL Queries Execution
### Tables, procedures, and functions will already be created using init-scripts.
### Open SQL files from the queries directory
### Create partition for transactions table
  sql_scripts/partition.sql
### Call data generation
  CALL generate_test_data();
### If you want to clear the data, call the truncate_test_data procedure.
  CALL truncate_test_data();
### If you want to calculate the total balance on all the client's cards at a certain point in time.
  SELECT get_client_balance(#Enter client_id, #Enter datetime)
### Open SQL files from the queries directory
  sql_scripts/5_queries 
### If you want to optimize queries, create an index.
  sql_scripts/indexes.sql

## To stop working with the repository and clean up:

  docker-compose down -v
