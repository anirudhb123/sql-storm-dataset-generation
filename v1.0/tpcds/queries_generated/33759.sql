
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_current_cdemo_sk,
        0 AS level
    FROM 
        customer
    WHERE 
        c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        ch.level + 1
    FROM 
        customer c
    JOIN 
        customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
)

SELECT 
    ca.ca_address_id,
    ca.ca_city,
    SUM(ws.ws_net_profit) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    (SELECT AVG(cd_purchase_estimate) FROM customer_demographics WHERE cd_gender = 'F') AS avg_female_purchase_estimate,
    DENSE_RANK() OVER (PARTITION BY ca.ca_city ORDER BY SUM(ws.ws_net_profit) DESC) AS city_sales_rank,
    CASE 
        WHEN SUM(ws.ws_net_profit) > 1000 THEN 'High Performer'
        WHEN SUM(ws.ws_net_profit) BETWEEN 500 AND 1000 THEN 'Average Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    web_sales ws
INNER JOIN 
    customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
LEFT JOIN 
    customer_hierarchy ch ON ws.ws_bill_customer_sk = ch.c_customer_sk
LEFT JOIN 
    customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_state = 'CA'
    AND ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 5)
GROUP BY 
    ca.ca_address_id, ca.ca_city
HAVING 
    SUM(ws.ws_net_profit) IS NOT NULL
ORDER BY 
    city_sales_rank, total_sales DESC;
