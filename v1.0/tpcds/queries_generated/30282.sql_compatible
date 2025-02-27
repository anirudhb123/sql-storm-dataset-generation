
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name, 
        c.c_last_name, 
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_profit,
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
        sh.total_profit + COALESCE(SUM(ss2.ss_net_profit), 0) AS total_profit,
        sh.level + 1
    FROM 
        SalesHierarchy sh
    LEFT JOIN 
        store_sales ss2 ON sh.c_customer_sk = ss2.ss_customer_sk
    GROUP BY 
        sh.c_customer_sk, sh.c_first_name, sh.c_last_name, sh.total_profit, sh.level
),
RankedSales AS (
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.total_profit,
        RANK() OVER (PARTITION BY sh.level ORDER BY sh.total_profit DESC) AS profit_rank
    FROM 
        SalesHierarchy sh
),
FinalResults AS (
    SELECT 
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        r.total_profit,
        r.profit_rank,
        CASE 
            WHEN r.profit_rank <= 5 THEN 'Top 5'
            ELSE 'Other'
        END AS rank_category
    FROM 
        RankedSales r
)
SELECT 
    fr.rank_category,
    AVG(fr.total_profit) AS avg_profit,
    COUNT(fr.c_customer_sk) AS customer_count
FROM 
    FinalResults fr
GROUP BY 
    fr.rank_category
HAVING 
    AVG(fr.total_profit) > (SELECT AVG(total_profit) FROM FinalResults WHERE total_profit IS NOT NULL)
ORDER BY 
    avg_profit DESC;
