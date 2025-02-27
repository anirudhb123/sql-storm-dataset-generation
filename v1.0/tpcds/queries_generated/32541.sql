
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk

    UNION ALL

    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        sales_data sd ON ws_item_sk = sd.ws_item_sk 
    WHERE 
        ws_sold_date_sk > sd.ws_sold_date_sk
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
top_items AS (
    SELECT 
        ws_item_sk, 
        total_quantity, 
        total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY total_sales DESC) AS sales_rank
    FROM sales_data
)
SELECT 
    ca.c_city,
    SUM(ti.total_quantity) AS total_quantity_sold,
    AVG(ti.total_sales) AS average_sales,
    COUNT(DISTINCT ca.ca_address_id) AS unique_addresses
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    top_items ti ON ti.ws_item_sk = c.c_customer_sk
WHERE 
    ca.ca_state = 'CA' AND
    (c.c_birth_month IS NULL OR c.c_birth_month BETWEEN 1 AND 6)
GROUP BY 
    ca.c_city
HAVING 
    SUM(ti.total_quantity) > 100
ORDER BY 
    average_sales DESC
LIMIT 10;
