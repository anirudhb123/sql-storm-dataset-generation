
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        s_store_sk,
        ss_sold_date_sk,
        SUM(ss_net_profit) AS total_net_profit,
        1 AS depth
    FROM 
        store_sales 
    WHERE 
        ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        s_store_sk, ss_sold_date_sk
    
    UNION ALL

    SELECT 
        sh.s_store_sk,
        sh.ss_sold_date_sk,
        SUM(ss.net_profit) + sh.total_net_profit AS total_net_profit,
        depth + 1
    FROM 
        SalesHierarchy sh
    JOIN 
        store_sales ss ON sh.s_store_sk = ss.s_store_sk AND sh.ss_sold_date_sk = ss.ss_sold_date_sk
    WHERE 
        depth < 5
)
, StorePerformance AS (
    SELECT 
        s.s_store_name,
        sh.ss_sold_date_sk,
        COALESCE(SUM(sh.total_net_profit), 0) AS accumulated_net_profit,
        MAX(s.s_number_employees) AS employees_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_transactions
    FROM 
        store s
    LEFT JOIN 
        SalesHierarchy sh ON s.s_store_sk = sh.s_store_sk
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.s_store_sk AND sh.ss_sold_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        s.s_store_name, sh.ss_sold_date_sk
)
SELECT 
    sp.s_store_name,
    date_dim.d_date AS sales_date,
    sp.accumulated_net_profit,
    sp.employees_count,
    CASE 
        WHEN sp.accumulated_net_profit IS NULL THEN 'No Sales'
        WHEN sp.accumulated_net_profit > 1000 THEN 'High Profit'
        WHEN sp.accumulated_net_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    StorePerformance sp
JOIN 
    date_dim ON sp.ss_sold_date_sk = date_dim.d_date_sk
WHERE 
    date_dim.d_year = 2023
ORDER BY 
    sales_date DESC, sp.accumulated_net_profit DESC;
