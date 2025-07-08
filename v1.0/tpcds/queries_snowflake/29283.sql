
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    COUNT(DISTINCT ws_order_number) AS total_web_orders,
    SUM(ws_net_profit) AS total_net_profit,
    AVG(LENGTH(c_first_name) + LENGTH(c_last_name)) AS avg_name_length,
    MIN(ws_sales_price) AS min_sales_price,
    MAX(ws_sales_price) AS max_sales_price,
    LISTAGG(DISTINCT w_country, ', ') AS unique_shipping_countries
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE 
    ca_country IN ('USA', 'Canada')
    AND c.c_current_cdemo_sk IS NOT NULL
    AND ws_sold_date_sk >= (
        SELECT 
            MAX(d_date_sk) 
        FROM 
            date_dim 
        WHERE 
            d_date >= '2023-01-01'
    )
GROUP BY 
    ca_state
ORDER BY 
    total_net_profit DESC, 
    unique_customers DESC;
