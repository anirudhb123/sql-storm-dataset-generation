
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_desc, i_brand, i_category
    FROM item
    WHERE i_item_sk IN (SELECT sr_item_sk FROM store_returns WHERE sr_return_quantity > 0)
    UNION ALL
    SELECT i.i_item_sk, i.i_item_desc, i.i_brand, i.i_category
    FROM item i
    JOIN item_hierarchy ih ON i.i_item_sk = ih.i_item_sk
),
customer_purchase AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, SUM(ws.ws_sales_price) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
return_details AS (
    SELECT sr_item_sk, COUNT(sr_ticket_number) AS return_count, SUM(sr_return_amt_inc_tax) AS return_total
    FROM store_returns
    GROUP BY sr_item_sk
),
combined_summary AS (
    SELECT ch.i_item_desc, ch.i_brand, cp.c_first_name, cp.c_last_name,
           COALESCE(cp.total_spent, 0) AS total_spent,
           COALESCE(rd.return_count, 0) AS return_count,
           COALESCE(rd.return_total, 0) AS return_total,
           RANK() OVER (PARTITION BY ch.i_brand ORDER BY COALESCE(cp.total_spent, 0) DESC) AS brand_rank
    FROM item_hierarchy ch
    LEFT JOIN customer_purchase cp ON ch.i_item_sk = cp.c_customer_sk
    LEFT JOIN return_details rd ON ch.i_item_sk = rd.sr_item_sk
)
SELECT * 
FROM combined_summary 
WHERE return_count > 0 
AND (total_spent IS NOT NULL OR return_total IS NOT NULL)
ORDER BY brand_rank;
