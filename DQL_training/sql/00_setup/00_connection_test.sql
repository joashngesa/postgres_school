SELECT
    current_database() as database_name,
    current_user as connected_user,
    current_schema() as active_schema,
    current_timestamp as connected_at;
