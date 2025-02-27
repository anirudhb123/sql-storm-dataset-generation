
WITH customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        (SELECT COUNT(*) 
         FROM store_sales ss 
         WHERE ss.ss_customer_sk = c.c_customer_sk) AS total_store_purchases,
        (SELECT COUNT(*)
         FROM web_sales ws
         WHERE ws.ws_ship_customer_sk = c.c_customer_sk) AS total_web_purchases,
        (SELECT AVG(ws.ws_net_profit) 
         FROM web_sales ws 
         WHERE ws.ws_ship_customer_sk = c.c_customer_sk) AS avg_web_profit,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.cd_gender, 
        cs.cd_marital_status,
        cs.total_store_purchases,
        cs.total_web_purchases,
        cs.avg_web_profit
    FROM 
        customer_summary cs
    WHERE 
        cs.purchase_rank <= 10
)

SELECT 
    tc.c_customer_id,
    COALESCE(tc.cd_gender, 'N/A') AS customer_gender,
    COALESCE(tc.cd_marital_status, 'Unknown') AS marital_status,
    COALESCE(tc.total_store_purchases, 0) AS store_purchases,
    COALESCE(tc.total_web_purchases, 0) AS web_purchases,
    COALESCE(tc.avg_web_profit, 0.00) AS avg_profit,
    CASE 
        WHEN tc.avg_web_profit > 100 THEN 'High Value'
        WHEN tc.avg_web_profit BETWEEN 50 AND 100 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_category
FROM 
    top_customers tc
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_id = tc.c_customer_id)
LEFT JOIN 
    date_dim dd ON (dd.d_date_sk = (SELECT MIN(ws.ws_ship_date_sk) FROM web_sales ws WHERE ws.ws_ship_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_customer_id = tc.c_customer_id)))
WHERE 
    dd.d_year >= (SELECT MAX(d_year) FROM date_dim) - 3
    AND (tc.total_store_purchases > 0 OR tc.total_web_purchases > 0)
ORDER BY 
    tc.total_store_purchases DESC, tc.total_web_purchases DESC;
