
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        1 AS level
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year <= 1980

    UNION ALL

    SELECT 
        s.ss_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        level + 1
    FROM 
        store_sales s
    JOIN 
        customer c ON s.ss_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_hierarchy sh ON sh.c_customer_sk = s.ss_customer_sk
    WHERE 
        s.ss_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2022)
)
SELECT 
    sh.c_customer_sk,
    sh.c_first_name,
    sh.c_last_name,
    COUNT(DISTINCT s.ss_order_number) AS total_orders,
    SUM(s.ss_ext_sales_price) AS total_sales,
    AVG(s.ss_net_profit) AS avg_net_profit,
    ROW_NUMBER() OVER (PARTITION BY sh.c_customer_sk ORDER BY total_sales DESC) AS rank
FROM 
    sales_hierarchy sh
LEFT JOIN 
    store_sales s ON sh.c_customer_sk = s.ss_customer_sk
GROUP BY 
    sh.c_customer_sk, sh.c_first_name, sh.c_last_name
HAVING 
    MAX(sh.level) > 1
ORDER BY 
    total_sales DESC
LIMIT 100;
