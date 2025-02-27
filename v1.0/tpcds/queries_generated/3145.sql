
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
top_items AS (
    SELECT ws_item_sk
    FROM ranked_sales
    WHERE rank <= 10
),
customer_activity AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid_inc_tax) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_current_addr_sk IS NOT NULL
    GROUP BY c.c_customer_sk
),
item_returns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned
    FROM store_returns
    GROUP BY sr_item_sk
),
item_summary AS (
    SELECT 
        i.i_item_sk,
        COALESCE(ir.total_returned, 0) AS total_returned,
        COALESCE(ws.total_quantity, 0) AS total_sold,
        COALESCE(ws.total_sales, 0) AS total_sales
    FROM item i
    LEFT JOIN top_items t ON i.i_item_sk = t.ws_item_sk
    LEFT JOIN ranked_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN item_returns ir ON i.i_item_sk = ir.sr_item_sk
    WHERE t.ws_item_sk IS NOT NULL
)
SELECT 
    im.i_item_sk,
    im.total_sold,
    im.total_returned,
    im.total_sales,
    CASE 
        WHEN im.total_sales > 0 THEN ROUND((im.total_returned::DECIMAL / im.total_sold) * 100, 2) 
        ELSE NULL 
    END AS return_percentage
FROM item_summary im
JOIN customer_activity ca ON im.i_item_sk IN (
    SELECT sr_item_sk FROM store_returns WHERE sr_customer_sk = ca.c_customer_sk 
    EXCEPT
    SELECT wr_item_sk FROM web_returns WHERE wr_returning_customer_sk = ca.c_customer_sk
)
WHERE ca.total_orders > 5
ORDER BY return_percentage DESC, ca.total_spent DESC;
