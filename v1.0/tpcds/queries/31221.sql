
WITH RECURSIVE CTE_Sales_Analysis AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim) 
    GROUP BY ss_store_sk
    
    UNION ALL
    
    SELECT 
        s.ss_store_sk,
        c.total_net_profit + (SUM(s.ss_net_profit) / NULLIF((SELECT COUNT(*) FROM store_sales WHERE ss_store_sk = s.ss_store_sk), 0)) AS total_net_profit,
        c.total_sales + COUNT(DISTINCT s.ss_ticket_number) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.ss_store_sk ORDER BY SUM(s.ss_net_profit) DESC) AS profit_rank
    FROM store_sales s
    JOIN CTE_Sales_Analysis c ON s.ss_store_sk = c.ss_store_sk
    WHERE s.ss_sold_date_sk < (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY s.ss_store_sk, c.total_net_profit, c.total_sales
)
SELECT 
    sa.ss_store_sk, 
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    COALESCE(c.c_email_address, 'N/A') AS email,
    sa.total_net_profit,
    sa.total_sales,
    DENSE_RANK() OVER (ORDER BY sa.total_net_profit DESC) AS store_rank
FROM CTE_Sales_Analysis sa
JOIN customer c ON c.c_customer_sk = (
    SELECT c_customer_sk 
    FROM store_sales 
    WHERE ss_store_sk = sa.ss_store_sk 
    ORDER BY ss_net_profit DESC 
    LIMIT 1
)
WHERE sa.total_net_profit IS NOT NULL
ORDER BY store_rank, sa.total_net_profit DESC;
