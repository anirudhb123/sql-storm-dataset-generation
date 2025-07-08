
WITH ranked_sales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_net_paid, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_net_paid > 1000
),
total_sales AS (
    SELECT 
        ws_item_sk, 
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
latest_returns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        COUNT(DISTINCT wr_order_number) AS unique_returns
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
)

SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(rs.rank, 0) AS highest_rank,
    COALESCE(ts.total_orders, 0) AS order_count,
    COALESCE(lr.total_returns, 0) AS returns,
    CASE 
        WHEN COALESCE(lr.unique_returns, 0) > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    (SELECT AVG(ws_net_paid) 
     FROM web_sales 
     WHERE ws_item_sk = i.i_item_sk AND ws_net_paid IS NOT NULL) AS avg_sales_price,
    (SELECT COUNT(DISTINCT ws_order_number) 
     FROM web_sales 
     WHERE ws_item_sk = i.i_item_sk) AS order_unique_count,
    (SELECT COUNT(*) FROM web_sales ws
     WHERE ws.ws_item_sk = i.i_item_sk AND 
           ws.ws_net_paid = (SELECT MAX(ws_net_paid) FROM web_sales WHERE ws_item_sk = i.i_item_sk)
    ) AS max_sales_count
FROM 
    item i
LEFT JOIN 
    ranked_sales rs ON i.i_item_sk = rs.ws_item_sk
LEFT JOIN 
    total_sales ts ON i.i_item_sk = ts.ws_item_sk
LEFT JOIN 
    latest_returns lr ON i.i_item_sk = lr.wr_item_sk
WHERE 
    i.i_current_price IS NOT NULL
ORDER BY 
    avg_sales_price DESC, 
    highest_rank DESC;
