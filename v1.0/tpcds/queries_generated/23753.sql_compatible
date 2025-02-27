
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rank_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim dd 
            WHERE dd.d_year = 2023 AND dd.d_month_seq BETWEEN 6 AND 12
        )
),
item_summary AS (
    SELECT 
        i.i_item_id,
        SUM(CASE WHEN rc.is_returned = 1 THEN 1 ELSE 0 END) AS returns,
        SUM(CASE WHEN rc.is_returned = 0 THEN 1 ELSE 0 END) AS sales,
        COUNT(DISTINCT rc.ws_order_number) AS order_count
    FROM 
        item i
    LEFT JOIN (
        SELECT 
            ws.ws_item_sk,
            ws.ws_order_number,
            0 AS is_returned
        FROM 
            web_sales ws

        UNION ALL

        SELECT 
            wr.wr_item_sk,
            wr.wr_order_number,
            1 AS is_returned
        FROM 
            web_returns wr
    ) rc ON i.i_item_sk = rc.ws_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    COALESCE(i_summary.i_item_id, 'No Sales') AS item_id,
    i_summary.sales,
    i_summary.returns,
    z.rank_sales AS best_rank
FROM 
    item_summary i_summary
FULL OUTER JOIN (
    SELECT 
        rs.ws_item_sk,
        MIN(rs.rank_sales) AS rank_sales
    FROM 
        ranked_sales rs
    GROUP BY 
        rs.ws_item_sk
) z ON i_summary.i_item_id = z.ws_item_sk
WHERE 
    (i_summary.sales > 0 OR z.rank_sales IS NOT NULL)
    AND (z.rank_sales IS NULL OR z.rank_sales <= 3)
ORDER BY 
    i_summary.sales DESC NULLS LAST;
