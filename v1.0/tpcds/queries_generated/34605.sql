
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_marital_status,
        cd_gender,
        cd_purchase_estimate,
        0 AS level
    FROM 
        customer
        JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE 
        cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
    
    UNION ALL
    
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.cd_marital_status,
        sh.cd_gender,
        sh.cd_purchase_estimate,
        sh.level + 1
    FROM 
        SalesHierarchy AS sh
        JOIN customer AS c ON c.c_current_hdemo_sk = sh.c_customer_sk
        JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_dep_count > 0
)
SELECT 
    sh.c_first_name || ' ' || sh.c_last_name AS customer_name,
    sh.cd_marital_status,
    sh.cd_gender,
    sh.cd_purchase_estimate,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_ext_sales_price) - SUM(ws_ext_discount_amt) AS net_sales_profit,
    ROW_NUMBER() OVER (PARTITION BY sh.level ORDER BY COUNT(DISTINCT ws_order_number) DESC) AS order_rank
FROM 
    SalesHierarchy sh
    LEFT JOIN web_sales ws ON sh.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                           AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
GROUP BY 
    sh.c_first_name, sh.c_last_name, sh.cd_marital_status, sh.cd_gender, sh.cd_purchase_estimate, sh.level
HAVING 
    COUNT(DISTINCT ws_order_number) > 5 OR net_sales_profit > 1000
ORDER BY 
    net_sales_profit DESC
LIMIT 50;
