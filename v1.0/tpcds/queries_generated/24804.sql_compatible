
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM 
        web_sales
),
total_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        rs.ws_quantity,
        COALESCE(ts.total_profit, 0) AS total_profit,
        CASE 
            WHEN ts.total_profit > 1000 THEN 'High Profit'
            WHEN ts.total_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
            ELSE 'Low Profit'
        END AS profit_category
    FROM 
        item
    JOIN 
        ranked_sales rs ON item.i_item_sk = rs.ws_item_sk
    LEFT JOIN 
        total_sales ts ON item.i_item_sk = ts.ws_item_sk
    WHERE 
        rs.price_rank = 1 AND rs.ws_quantity > 10 
),
customer_returns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(DISTINCT wr_order_number) AS return_count,
        SUM(wr_net_loss) AS total_return_loss
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.ws_quantity,
    ti.total_profit,
    ti.profit_category,
    cr.return_count,
    cr.total_return_loss
FROM 
    top_items ti
JOIN 
    customer_returns cr ON ti.ws_quantity > cr.return_count
WHERE 
    ti.profit_category = 'High Profit'
    AND EXISTS (
        SELECT 1 
        FROM customer c 
        WHERE c.c_customer_sk = cr.wr_returning_customer_sk 
        AND c.c_current_cdemo_sk IS NOT NULL
    )
ORDER BY 
    ti.total_profit DESC, 
    cr.total_return_loss ASC
LIMIT 100
OFFSET (SELECT COUNT(DISTINCT ws_bill_customer_sk) FROM web_sales WHERE ws_sales_price IS NOT NULL) / 10;
