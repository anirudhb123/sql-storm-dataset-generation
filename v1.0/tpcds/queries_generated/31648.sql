
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_purchase_estimate,
        0 AS level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_purchase_estimate,
        ch.level + 1
    FROM 
        customer c
    JOIN 
        CustomerHierarchy ch ON c.c_current_addr_sk = ch.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 500
)

SELECT 
    ch.c_customer_sk,
    CONCAT(ch.c_first_name, ' ', ch.c_last_name) AS full_name,
    ch.cd_gender,
    ch.cd_marital_status,
    (SELECT AVG(cd_purchase_estimate) 
     FROM customer_demographics 
     WHERE cd_income_band_sk = ch.cd_income_band_sk) AS average_estimate,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    ROW_NUMBER() OVER (PARTITION BY ch.cd_gender ORDER BY total_net_profit DESC) AS gender_rank
FROM 
    CustomerHierarchy ch
LEFT JOIN 
    web_sales ws ON ch.c_customer_sk = ws.ws_ship_customer_sk
WHERE 
    ch.cd_marital_status = 'M'
GROUP BY 
    ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.cd_gender, ch.cd_marital_status, ch.cd_income_band_sk
HAVING 
    total_net_profit > 5000 
ORDER BY 
    gender_rank
LIMIT 10;
