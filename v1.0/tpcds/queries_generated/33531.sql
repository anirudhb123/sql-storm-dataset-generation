
WITH RECURSIVE SalesGrowth AS (
    SELECT
        ss_store_sk,
        SUM(ss_net_profit) as total_profit,
        DENSE_RANK() OVER (ORDER BY SUM(ss_net_profit) DESC) as profit_rank
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 365 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ss_store_sk
),
TopStores AS (
    SELECT
        sg.ss_store_sk,
        sg.total_profit,
        ROW_NUMBER() OVER (ORDER BY sg.total_profit DESC) as store_rank
    FROM SalesGrowth sg
    WHERE sg.total_profit > (SELECT AVG(total_profit) FROM SalesGrowth)
),
CustomerReturns AS (
    SELECT
        sr_store_sk,
        COUNT(DISTINCT sr_ticket_number) as total_returns,
        SUM(sr_return_amt) as total_return_amount
    FROM store_returns
    GROUP BY sr_store_sk
)
SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    ts.total_profit,
    cr.total_returns,
    cr.total_return_amount,
    CASE 
        WHEN cr.total_return_amount IS NULL THEN 'No Returns'
        ELSE CONCAT('$', CAST(cr.total_return_amount AS CHAR))
    END as formatted_return_amount,
    IFNULL(CAST(ts.total_profit / NULLIF(cr.total_returns, 0) AS DECIMAL(10, 2)), 0) as avg_profit_per_return
FROM store s
LEFT JOIN TopStores ts ON s.s_store_sk = ts.ss_store_sk
LEFT JOIN CustomerReturns cr ON s.s_store_sk = cr.sr_store_sk
WHERE s.s_state = 'CA'
ORDER BY ts.total_profit DESC, s.s_city;
