
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 0 AS level
    FROM customer
    WHERE c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer)

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
)

SELECT 
    c.c_customer_id, 
    ca.ca_city, 
    cd.cd_gender, 
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) OVER (PARTITION BY ca.ca_state) AS avg_net_profit_per_state,
    CASE 
        WHEN cd.cd_marital_status = 'M' THEN 'Married'
        WHEN cd.cd_marital_status = 'S' THEN 'Single'
        ELSE 'Other' 
    END AS marital_status,
    CASE 
        WHEN cd.cd_credit_rating IS NULL THEN 'No Rating'
        ELSE cd.cd_credit_rating 
    END AS credit_rating,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY total_sales DESC) AS sales_rank
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_city IS NOT NULL
    AND ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
GROUP BY 
    c.c_customer_id, ca.ca_city, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating, ca.ca_state
HAVING 
    total_sales > 1000
ORDER BY 
    avg_net_profit_per_state DESC, sales_rank;
