
WITH CustomerWarehouses AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        w.w_warehouse_name,
        w.w_city AS warehouse_city,
        w.w_country AS warehouse_country,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
        CONCAT(w.w_street_number, ' ', w.w_street_name, ' ', w.w_street_type) AS warehouse_full_address
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        warehouse w ON w.w_warehouse_sk = (SELECT MAX(w2.w_warehouse_sk) 
                                             FROM warehouse w2 
                                             WHERE w2.w_city = ca.ca_city 
                                             AND w2.w_state = ca.ca_state)
    WHERE 
        ca.ca_country = 'USA'
),
StringBenchmarks AS (
    SELECT 
        customer_full_name,
        warehouse_full_address,
        LENGTH(customer_full_name) AS name_length,
        LENGTH(warehouse_full_address) AS address_length,
        UPPER(customer_full_name) AS name_upper,
        LOWER(warehouse_full_address) AS address_lower,
        REPLACE(customer_full_name, ' ', '-') AS name_hyphenated
    FROM 
        CustomerWarehouses
)
SELECT 
    name_length,
    address_length,
    COUNT(*) AS total_customers,
    ARRAY_AGG(name_upper) AS all_names_upper,
    ARRAY_AGG(address_lower) AS all_addresses_lower,
    AVG(name_length) AS avg_name_length,
    AVG(address_length) AS avg_address_length
FROM 
    StringBenchmarks
GROUP BY 
    name_length,
    address_length
ORDER BY 
    total_customers DESC;
