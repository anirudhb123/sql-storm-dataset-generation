
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        1 AS sales_level,
        SUM(ws_net_profit) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c_customer_sk, c_first_name, c_last_name

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.sales_level + 1 AS sales_level,
        SUM(ws.ws_net_profit) AS total_sales
    FROM 
        sales_hierarchy sh
    JOIN 
        customer c ON sh.c_customer_sk = c.c_current_cdemo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, sh.sales_level
)

SELECT 
    s.c_first_name,
    s.c_last_name,
    s.sales_level,
    COALESCE(SUM(s.total_sales), 0) AS total_sales,
    ROW_NUMBER() OVER (PARTITION BY s.sales_level ORDER BY COALESCE(SUM(s.total_sales), 0) DESC) AS sales_rank
FROM 
    sales_hierarchy s
GROUP BY 
    s.c_first_name, s.c_last_name, s.sales_level
ORDER BY 
    s.sales_level, sales_rank
LIMIT 10;

-- Performance Benchmarking Insights
-- 1. Evaluates sales data along a recursive hierarchy of customer relationships
-- 2. Uses window functions to rank total sales at each level
-- 3. Combines inner queries for date range filtering
-- 4. Utilizes COALESCE for handling NULLs in total sales 
