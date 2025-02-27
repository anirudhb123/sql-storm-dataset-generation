
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        0 AS level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year <= (SELECT MAX(d_year) FROM date_dim) - 18
    
    UNION ALL
    
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        level + 1
    FROM 
        sales_hierarchy sh
    JOIN 
        customer c ON sh.c_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
)
SELECT 
    s.c_first_name,
    s.c_last_name,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    MAX(ws.ws_net_profit) AS max_profit,
    MIN(ws.ws_net_paid) AS min_paid,
    ROUND(AVG(ws.ws_net_paid_inc_ship_tax), 2) AS avg_paid_incl_shipping,
    s.level
FROM 
    sales_hierarchy s
LEFT JOIN 
    web_sales ws ON s.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ws.ws_ship_date_sk IS NOT NULL
GROUP BY 
    s.c_first_name, 
    s.c_last_name, 
    s.level
HAVING 
    SUM(ws.ws_ext_sales_price) > 5000 
    AND COUNT(DISTINCT ws.ws_order_number) > 2 
ORDER BY 
    total_sales DESC
LIMIT 10;

-- Performance metrics
SELECT 
    COUNT(*) AS total_rows_processed,
    COUNT(DISTINCT c_customer_sk) AS distinct_customers,
    AVG(total_sales) AS avg_sales,
    MAX(total_sales) AS max_sales
FROM (
    SELECT 
        s.c_first_name,
        s.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        sales_hierarchy s
    LEFT JOIN 
        web_sales ws ON s.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        s.c_first_name, 
        s.c_last_name
) sales_summary;
