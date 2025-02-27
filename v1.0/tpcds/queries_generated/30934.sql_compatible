
WITH RECURSIVE SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        (ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_item_sk) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(sd.total_sales) AS total_sales_per_city,
    COUNT(DISTINCT sd.ws_order_number) AS order_count,
    AVG(sd.ws_quantity) AS avg_quantity_per_order,
    STRING_AGG(DISTINCT i.i_item_desc, ', ') AS sold_items,
    MAX(sd.total_sales) OVER (PARTITION BY ca.ca_city) AS max_city_sales,
    MIN(sd.total_sales) OVER (PARTITION BY ca.ca_city) AS min_city_sales
FROM 
    SalesData sd
JOIN 
    customer c ON c.c_customer_sk = sd.ws_item_sk
JOIN 
    customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    item i ON i.i_item_sk = sd.ws_item_sk
WHERE 
    sd.total_sales IS NOT NULL
    AND ca.ca_state IS NOT NULL
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT sd.ws_order_number) > 10
ORDER BY 
    total_sales_per_city DESC
LIMIT 10;
