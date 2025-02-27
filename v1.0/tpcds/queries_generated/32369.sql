
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        0 AS level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year < 1980
    
    UNION ALL
    
    SELECT 
        s.ss_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        sh.level + 1
    FROM 
        store_sales s
    JOIN 
        sales_hierarchy sh ON s.ss_customer_sk = sh.c_customer_sk
    JOIN 
        customer c ON s.ss_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)

SELECT 
    sh.c_customer_sk,
    CONCAT(sh.c_first_name, ' ', sh.c_last_name) AS customer_name,
    sh.cd_gender,
    sh.cd_marital_status,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    MAX(CASE WHEN ws.ws_sales_price > 100 THEN 'High Value' ELSE 'Regular' END) AS customer_value_category,
    DENSE_RANK() OVER (PARTITION BY sh.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_profit_rank
FROM 
    sales_hierarchy sh
LEFT JOIN 
    web_sales ws ON sh.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    sh.c_customer_sk, sh.c_first_name, sh.c_last_name, sh.cd_gender, sh.cd_marital_status
HAVING 
    total_net_profit > 1000 
ORDER BY 
    total_net_profit DESC
LIMIT 10;
