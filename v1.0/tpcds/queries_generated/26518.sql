
WITH RECURSIVE StringProcessing AS (
    SELECT 
        w.w_warehouse_id AS warehouse_id,
        CONCAT(w.w_warehouse_name, ' - ', w.ca_street_name, ', ', w.ca_city, ', ', w.ca_state) AS full_address,
        LENGTH(CONCAT(w.w_warehouse_name, ' - ', w.ca_street_name, ', ', w.ca_city, ', ', w.ca_state)) AS address_length
    FROM 
        warehouse w
    JOIN 
        customer_address ca ON w.w_warehouse_sk = ca.ca_address_sk
    WHERE 
        w.w_warehouse_name IS NOT NULL
    UNION ALL
    SELECT 
        warehouse_id,
        REPLACE(UPPER(full_address), ' ', '_') AS full_address,
        LENGTH(REPLACE(UPPER(full_address), ' ', '_')) AS address_length
    FROM 
        StringProcessing
    WHERE 
        address_length < 1000
)
SELECT 
    warehouse_id, 
    full_address, 
    address_length
FROM 
    StringProcessing
WHERE 
    address_length >= 100;
