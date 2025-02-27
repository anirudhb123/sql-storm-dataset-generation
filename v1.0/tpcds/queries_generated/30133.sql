
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        cs.customer_sk,
        1 AS level,
        cs.cs_net_profit AS profit
    FROM 
        customer AS cs
    JOIN 
        store_sales AS ss ON cs.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk = (
            SELECT MAX(ss2.ss_sold_date_sk) 
            FROM store_sales AS ss2 
            WHERE ss2.ss_customer_sk = cs.c_customer_sk
        ) 
    
    UNION ALL
    
    SELECT 
        cs.customer_sk,
        sh.level + 1,
        sh.profit + COALESCE(ss.cs_net_profit, 0)
    FROM 
        SalesHierarchy AS sh
    LEFT JOIN 
        store_sales AS ss ON sh.customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk = sh.level
)

SELECT 
    da.d_year,
    SUM(coalesce(sh.profit, 0)) AS total_profit,
    COUNT(sh.customer_sk) AS customer_count,
    AVG(sh.profit) AS avg_profit,
    MAX(sh.profit) AS max_profit,
    MIN(sh.profit) AS min_profit
FROM 
    date_dim AS da
LEFT JOIN 
    SalesHierarchy AS sh ON da.d_date_sk = sh.customer_sk
WHERE 
    da.d_year BETWEEN 2020 AND 2023
GROUP BY 
    da.d_year
ORDER BY 
    da.d_year;
