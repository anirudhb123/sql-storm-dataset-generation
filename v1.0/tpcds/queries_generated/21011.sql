
WITH RECURSIVE customer_orders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.cs_order_number,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cs.cs_order_number DESC) AS order_rank
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    WHERE c.c_first_name IS NOT NULL
),
promo_summary AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM promotion p
    LEFT JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_id
),
item_sales AS (
    SELECT 
        i.i_item_sk,
        SUM(COALESCE(ws.ws_quantity, 0) + COALESCE(cs.cs_quantity, 0) + COALESCE(ss.ss_quantity, 0)) AS total_sales
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY i.i_item_sk
),
popular_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        is.total_sales,
        RANK() OVER (ORDER BY is.total_sales DESC) AS sales_rank
    FROM item_sales is
    JOIN item i ON is.i_item_sk = i.i_item_sk
),
return_analysis AS (
    SELECT 
        sr.reason_sk,
        COUNT(sr.sr_return_quantity) AS total_returns,
        SUM(sr.sr_return_amt) AS total_returned_amount
    FROM store_returns sr
    GROUP BY sr.reason_sk
)
SELECT 
    co.c_first_name,
    co.c_last_name,
    pi.i_item_desc,
    pi.sales_rank,
    ps.promo_id,
    ps.total_orders,
    ps.total_profit,
    ra.total_returns,
    ra.total_returned_amount
FROM customer_orders co
JOIN popular_items pi ON co.order_rank <= 5
JOIN promo_summary ps ON ps.total_orders > 10
LEFT JOIN return_analysis ra ON ra.reason_sk IS NOT NULL
WHERE pi.sales_rank <= 10 
AND COALESCE(ps.total_profit, 0) > 1000
ORDER BY ra.total_returned_amount DESC, ps.total_profit ASC
LIMIT 50;
