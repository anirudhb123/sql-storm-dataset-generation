
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, c.c_birth_year

    UNION ALL

    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        sh.total_profit * 1.1 AS total_profit
    FROM 
        SalesHierarchy sh
    JOIN 
        customer c ON c.c_customer_id = sh.c_customer_id
    WHERE 
        c.c_birth_year < sh.c_birth_year
)

SELECT 
    s.c_customer_id,
    s.c_first_name,
    s.c_last_name,
    DENSE_RANK() OVER (ORDER BY SUM(s.total_profit) DESC) AS rank,
    CASE 
        WHEN SUM(s.total_profit) IS NULL THEN 'No Profit'
        ELSE CONCAT('Profit: $', CAST(ROUND(SUM(s.total_profit), 2) AS STRING))
    END AS profit_summary
FROM 
    SalesHierarchy s
GROUP BY 
    s.c_customer_id, s.c_first_name, s.c_last_name
HAVING 
    SUM(s.total_profit) > 0
ORDER BY 
    rank
LIMIT 10;
