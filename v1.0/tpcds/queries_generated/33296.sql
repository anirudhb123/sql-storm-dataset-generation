
WITH RECURSIVE sales_growth AS (
    SELECT 
        s_store_sk, 
        SUM(ss_net_profit) AS total_net_profit,
        1 AS level
    FROM store_sales
    GROUP BY s_store_sk
    
    UNION ALL
    
    SELECT 
        ss.s_store_sk, 
        SUM(ss.ss_net_profit) * (1 + (1.0 / (rg.level + 1))) AS total_net_profit,
        rg.level + 1
    FROM store_sales ss
    JOIN sales_growth rg ON ss.s_store_sk = rg.s_store_sk
    WHERE rg.level < 4
    GROUP BY ss.s_store_sk, rg.level
),
customer_return_data AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr_returned_date_sk) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk
),
highest_returning_customers AS (
    SELECT 
        cr.c_customer_sk,
        cr.total_returns,
        cr.total_return_amount,
        DENSE_RANK() OVER (ORDER BY cr.total_return_amount DESC) AS return_rank
    FROM customer_return_data cr
    WHERE cr.total_returns > 0
)
SELECT 
    s.s_store_sk,
    s.total_net_profit, 
    rc.total_returns,
    rc.total_return_amount,
    CASE 
        WHEN rc.return_rank IS NOT NULL THEN 'Returning'
        ELSE 'Non-returning'
    END AS return_status
FROM sales_growth s
LEFT JOIN highest_returning_customers rc ON s.s_store_sk = rc.c_customer_sk
WHERE s.total_net_profit > (SELECT AVG(total_net_profit) FROM sales_growth) 
ORDER BY s.total_net_profit DESC;
