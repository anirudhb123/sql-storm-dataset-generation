
WITH RECURSIVE SalesHierarchy AS (
    SELECT
        ss_store_sk,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_sales,
        1 AS level
    FROM
        store_sales
    GROUP BY
        ss_store_sk
    
    UNION ALL

    SELECT
        sr_store_sk,
        SUM(sr_net_loss) AS total_net_profit,
        COUNT(DISTINCT sr_ticket_number) AS total_sales,
        level + 1
    FROM
        store_returns sr
    JOIN SalesHierarchy sh ON sh.ss_store_sk = sr.sr_store_sk
    GROUP BY
        sr_store_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    COALESCE(sh.total_net_profit, 0) AS total_net_profit,
    COALESCE(sh.total_sales, 0) AS total_sales,
    CASE
        WHEN sh.total_net_profit > 10000 THEN 'High Profit'
        WHEN sh.total_net_profit > 5000 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d.d_date AS sales_date,
    ROW_NUMBER() OVER(PARTITION BY s.s_store_id ORDER BY COALESCE(sh.total_sales, 0) DESC) AS sales_rank
FROM
    store s
LEFT JOIN SalesHierarchy sh ON s.s_store_sk = sh.ss_store_sk
LEFT JOIN customer c ON c.c_customer_sk = sh.ss_store_sk -- assuming customer_sk corresponds for example purposes
LEFT JOIN date_dim d ON d.d_date_sk = CURRENT_DATE -- assuming today's date dimension for demo
WHERE
    (c.c_state IS NULL OR c.c_state = 'CA')
    AND sh.total_sales > 0
ORDER BY
    sales_rank, total_net_profit DESC;
