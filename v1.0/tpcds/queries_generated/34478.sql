
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_current_price, i_brand, 1 AS level
    FROM item
    WHERE i_current_price > 100.00
    UNION ALL
    SELECT ih.i_item_sk, ih.i_item_id, ih.i_item_desc, ih.i_current_price, ih.i_brand, ih.level + 1
    FROM ItemHierarchy ih
    JOIN item i ON i.i_item_sk = ih.i_item_sk
    WHERE ih.level < 5
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        SUM(sr_return_quantity) AS total_return_qty
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk
),
SalesStats AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS avg_net_profit
    FROM web_sales ws 
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.ws_bill_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    cs.total_returns,
    cs.total_return_amt,
    cs.total_return_qty,
    ss.total_sales,
    ss.total_orders,
    ss.avg_net_profit,
    ih.i_item_id,
    ih.i_item_desc,
    ih.level AS item_level
FROM customer c
LEFT JOIN CustomerStats cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN SalesStats ss ON c.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN ItemHierarchy ih ON ih.i_item_sk IN (SELECT sr_item_sk FROM store_returns WHERE sr_customer_sk = c.c_customer_sk)
WHERE 
    c.c_current_cdemo_sk IS NOT NULL 
    AND (cs.total_returns IS NULL OR cs.total_returns > 0)
ORDER BY total_sales DESC, cs.total_return_amt DESC;
