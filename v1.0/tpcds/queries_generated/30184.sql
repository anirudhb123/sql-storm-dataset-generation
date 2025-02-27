
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_sales,
        1 AS level
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    
    UNION ALL
    
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.total_sales * 1.1 AS total_sales,
        sh.level + 1
    FROM 
        sales_hierarchy sh
    JOIN 
        customer_address ca ON sh.c_customer_sk = ca.ca_address_sk
    WHERE 
        sh.level < 3
),
sales_summary AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(ss.ss_net_profit) AS store_profit,
        (SELECT COUNT(DISTINCT c.c_customer_sk) FROM customer c) AS total_customers,
        (SELECT COUNT(DISTINCT s.s_store_sk) FROM store s) AS total_stores
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    s.d_year,
    s.web_profit,
    s.store_profit,
    (s.web_profit + s.store_profit) / NULLIF(s.total_customers, 0) AS profit_per_customer,
    (s.web_profit + s.store_profit) / NULLIF(s.total_stores, 0) AS profit_per_store,
    sh.c_first_name,
    sh.c_last_name,
    sh.total_sales
FROM 
    sales_summary s
LEFT JOIN 
    sales_hierarchy sh ON sh.level = 1
WHERE 
    s.d_year >= 2020
ORDER BY 
    profit_per_customer DESC, total_sales DESC;
