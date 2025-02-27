
WITH ranked_sales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS revenue_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
),
high_revenue_sales AS (
    SELECT 
        r.ws_item_sk,
        SUM(r.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_count
    FROM ranked_sales r
    WHERE r.revenue_rank <= 10
    GROUP BY r.ws_item_sk
),
top_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        h.total_profit,
        h.sales_count,
        r.r_reason_desc
    FROM high_revenue_sales h
    JOIN item i ON h.ws_item_sk = i.i_item_sk
    LEFT JOIN reason r ON r.r_reason_sk = (SELECT sr_reason_sk FROM store_returns WHERE sr_item_sk = h.ws_item_sk LIMIT 1)
)
SELECT 
    t.i_item_id,
    t.i_item_desc,
    t.total_profit,
    t.sales_count,
    (SELECT COUNT(DISTINCT sr_store_sk) FROM store_returns sr WHERE sr_item_sk = t.ws_item_sk) AS return_count,
    (SELECT COUNT(DISTINCT wr_web_page_sk) FROM web_returns wr WHERE wr_item_sk = t.ws_item_sk) AS web_return_count
FROM top_items t
ORDER BY t.total_profit DESC, t.sales_count DESC
LIMIT 50;
