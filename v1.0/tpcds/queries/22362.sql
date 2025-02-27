
WITH RECURSIVE AddressHierarchy AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        CASE 
            WHEN ca_state IS NULL THEN 'Unknown' 
            ELSE ca_state 
        END AS state_group
    FROM 
        customer_address
    WHERE 
        ca_location_type = 'Residential'
    
    UNION ALL
    
    SELECT 
        c.ca_address_sk,
        c.ca_city,
        c.ca_state,
        c.ca_country,
        'Aggregate' AS state_group
    FROM 
        customer_address c
    JOIN AddressHierarchy ah ON c.ca_state = ah.state_group
)

SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name,
    da.d_date,
    SUM(COALESCE(ws.ws_sales_price, 0)) AS total_sales, 
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    CASE 
        WHEN SUM(ws.ws_sales_price) > 1000 THEN 'VIP'
        WHEN SUM(ws.ws_sales_price) BETWEEN 500 AND 1000 THEN 'Regular'
        ELSE 'New'
    END AS customer_status,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY da.d_date DESC) AS order_rank
FROM 
    customer c
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim da ON da.d_date_sk = ws.ws_sold_date_sk
LEFT JOIN 
    AddressHierarchy ah ON ah.ca_address_sk = c.c_current_addr_sk
WHERE 
    da.d_year = 2023
    AND (ah.state_group IS NOT NULL OR ah.ca_country != 'N/A')
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name,
    da.d_date
HAVING 
    SUM(COALESCE(ws.ws_sales_price, 0)) > 100
ORDER BY 
    total_sales DESC
LIMIT 10;
