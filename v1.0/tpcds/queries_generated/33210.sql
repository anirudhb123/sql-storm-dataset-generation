
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.sold_date_sk,
        ws.item_sk,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(ws.order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.item_sk ORDER BY SUM(ws.net_profit) DESC) AS rank 
    FROM web_sales ws
    INNER JOIN date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.sold_date_sk, ws.item_sk
    HAVING SUM(ws.net_profit) IS NOT NULL
),
top_sales AS (
    SELECT item_sk, total_net_profit, order_count
    FROM sales_summary
    WHERE rank <= 10
)
SELECT 
    i.item_id,
    i.item_desc,
    COALESCE(ts.total_net_profit, 0) AS total_net_profit,
    COALESCE(ts.order_count, 0) AS order_count,
    CASE 
        WHEN ts.order_count > 0 THEN ts.total_net_profit / ts.order_count
        ELSE 0 
    END AS average_net_profit_per_order,
    r.r_reason_desc AS return_reason
FROM item i
LEFT JOIN top_sales ts ON i.i_item_sk = ts.item_sk
LEFT JOIN web_returns wr ON i.i_item_sk = wr.wr_item_sk
LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
WHERE i.i_current_price > 20
ORDER BY total_net_profit DESC, order_count DESC;
