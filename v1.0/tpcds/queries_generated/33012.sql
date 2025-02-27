
WITH RECURSIVE item_hierarchy AS (
    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_current_price, 
           CAST(NULL AS DECIMAL(7,2)) AS parent_price, 
           0 AS level
    FROM item i
    WHERE i.i_item_sk IS NOT NULL
    
    UNION ALL
    
    SELECT ih.i_item_sk, ih.i_item_id, ih.i_item_desc, ih.i_current_price, 
           ih.i_current_price AS parent_price, 
           ih.level + 1
    FROM item_hierarchy ih
    JOIN item i ON i.i_item_sk = ih.i_item_sk - 1
    WHERE ih.level < 10
), sales_summary AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_sold
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id
),
top_customers AS (
    SELECT 
        c.c_customer_id, s.total_profit, s.order_count,
        RANK() OVER (ORDER BY s.total_profit DESC) AS rank
    FROM sales_summary s
    JOIN customer c ON s.c_customer_id = c.c_customer_id
    WHERE s.total_profit IS NOT NULL
)
SELECT 
    th.c_customer_id,
    th.total_profit,
    th.order_count,
    ih.i_item_desc,
    ih.i_current_price,
    ih.parent_price,
    CASE 
        WHEN th.order_count > 10 THEN 'Loyal Customer'
        ELSE 'Occasional Customer'
    END AS customer_type,
    COALESCE(th.rank, 0) AS customer_rank
FROM top_customers th
LEFT JOIN item_hierarchy ih ON ih.i_item_sk = (SELECT MAX(ws.ws_item_sk)
                                               FROM web_sales ws 
                                               WHERE ws.ws_bill_customer_sk = th.c_customer_id)
WHERE th.rank <= 100
ORDER BY th.total_profit DESC, th.c_customer_id;
