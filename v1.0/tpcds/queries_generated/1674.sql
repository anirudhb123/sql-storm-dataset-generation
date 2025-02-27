
WITH customer_returns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr_order_number) AS total_return_count
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_sales_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
join_results AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(s.total_net_profit, 0) AS total_net_profit,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        s.total_sales_count
    FROM customer c
    LEFT JOIN sales_summary s ON c.c_customer_sk = s.customer_sk
    LEFT JOIN customer_returns r ON c.c_customer_sk = r.cr_returning_customer_sk
),
customer_rank AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_net_profit DESC, total_return_count ASC) AS profit_rank,
        DENSE_RANK() OVER (PARTITION BY CASE WHEN total_sales_count > 10 THEN 'High' ELSE 'Low' END ORDER BY total_net_profit DESC) AS sales_rank
    FROM join_results
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.total_net_profit,
    c.total_return_amount,
    c.profit_rank,
    c.sales_rank,
    CASE 
        WHEN c.total_return_amount > 0 THEN 'Has Returns'
        ELSE 'No Returns'
    END AS return_status
FROM customer_rank c
WHERE c.total_net_profit > 500
ORDER BY c.profit_rank, c.sales_rank;
