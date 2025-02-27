
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        1 AS level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_first_name IS NOT NULL

    UNION ALL

    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.cd_gender,
        sh.cd_marital_status,
        sh.cd_purchase_estimate,
        sh.level + 1
    FROM 
        customer c
    JOIN 
        sales_hierarchy sh ON c.c_first_shipto_date_sk = sh.c_customer_sk
    WHERE 
        sh.level < 5 -- Limit the recursion depth
),

total_sales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),

store_sales_summary AS (
    SELECT 
        ss.ss_customer_sk,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(ss.ss_ticket_number) AS store_order_count
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_customer_sk
)

SELECT 
    sh.c_customer_sk,
    sh.c_first_name || ' ' || sh.c_last_name AS full_name,
    sh.cd_gender,
    sh.cd_marital_status,
    COALESCE(ts.total_net_profit, 0) AS web_total_net_profit,
    COALESCE(ts.order_count, 0) AS web_order_count,
    COALESCE(ss.store_net_profit, 0) AS store_total_net_profit,
    COALESCE(ss.store_order_count, 0) AS store_order_count,
    CASE 
        WHEN ts.total_net_profit IS NULL AND ss.store_net_profit IS NULL THEN 'No Sales'
        WHEN ts.total_net_profit > ss.store_net_profit THEN 'Higher in Web Sales'
        ELSE 'Higher in Store Sales'
    END AS sales_comparison
FROM 
    sales_hierarchy sh
LEFT JOIN 
    total_sales ts ON sh.c_customer_sk = ts.ws_bill_customer_sk
LEFT JOIN 
    store_sales_summary ss ON sh.c_customer_sk = ss.ss_customer_sk
ORDER BY 
    sh.level DESC, 
    sh.c_last_name, 
    sh.c_first_name;
