
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        ca.ca_city,
        ca.ca_state,
        1 AS level
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_marital_status = 'M' 
    UNION ALL
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ch.cd_marital_status,
        ch.cd_gender,
        ch.ca_city,
        ch.ca_state,
        ch.level + 1
    FROM 
        CustomerHierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_customer_sk
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ch.ca_city,
    ch.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_revenue,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    MAX(ws.ws_net_profit) AS max_profit
FROM 
    CustomerHierarchy ch
LEFT JOIN 
    web_sales ws ON ch.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    store_sales ss ON ch.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    catalog_sales cs ON ch.c_customer_sk = cs.cs_bill_customer_sk
WHERE 
    (ws.ws_ship_date_sk IS NOT NULL OR ss.ss_sold_date_sk IS NOT NULL OR cs.cs_sold_date_sk IS NOT NULL)
GROUP BY 
    ch.c_first_name, ch.c_last_name, ch.ca_city, ch.ca_state
HAVING 
    total_orders > 0 AND
    MAX(ws.ws_net_profit) IS NOT NULL
ORDER BY 
    total_revenue DESC
LIMIT 50;
