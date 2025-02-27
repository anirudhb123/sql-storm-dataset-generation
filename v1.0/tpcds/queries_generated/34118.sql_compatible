
WITH RECURSIVE sales_per_store AS (
    SELECT 
        s_store_sk, 
        SUM(ss_net_profit) AS total_profit
    FROM store_sales 
    WHERE ss_sold_date_sk >= 20230101 
    GROUP BY s_store_sk 
    UNION ALL 
    SELECT 
        s_store_sk, 
        SUM(ws_net_profit) AS total_profit
    FROM web_sales 
    WHERE ws_sold_date_sk >= 20230101 
    GROUP BY s_store_sk
),
customer_segments AS (
    SELECT 
        cid.c_customer_sk,
        SUM(COALESCE(sr_return_amount, 0)) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM customer cid
    LEFT JOIN store_returns sr ON cid.c_customer_sk = sr.sr_customer_sk
    GROUP BY cid.c_customer_sk
),
enriched_sales AS (
    SELECT 
        ss.s_store_sk,
        ss.ss_item_sk,
        SUM(ss.ss_net_profit) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY ss.s_store_sk ORDER BY SUM(ss.ss_net_profit) DESC) AS sales_rank
    FROM store_sales ss
    GROUP BY ss.s_store_sk, ss.ss_item_sk
),
top_stores AS (
    SELECT s_store_sk, total_profit
    FROM sales_per_store
    ORDER BY total_profit DESC
    LIMIT 10
)
SELECT 
    e.s_store_sk,
    e.ss_item_sk,
    e.total_sales,
    cs.total_returns,
    cs.return_count,
    CASE 
        WHEN cs.return_count > 0 THEN (e.total_sales - cs.total_returns) / NULLIF(e.total_sales, 0)
        ELSE e.total_sales
    END AS net_sales_adjusted,
    CASE 
        WHEN e.total_transactions > 100 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS sales_volume_category
FROM enriched_sales e
JOIN top_stores ts ON e.s_store_sk = ts.s_store_sk
LEFT JOIN customer_segments cs ON e.s_store_sk = cs.c_customer_sk
WHERE e.sales_rank <= 5
ORDER BY e.total_sales DESC;
