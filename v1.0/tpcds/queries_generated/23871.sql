
WITH RECURSIVE recent_sales AS (
    SELECT ws_item_sk, 
           SUM(ws_quantity) AS total_quantity, 
           SUM(ws_net_paid) AS total_net_paid,
           RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rank_order
    FROM web_sales
    GROUP BY ws_item_sk
), 
customer_purchases AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           COUNT(DISTINCT ws_order_number) AS purchase_count,
           SUM(ws_net_paid) AS total_spent,
           SUM(ws_quantity) AS total_items_bought
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year IS NOT NULL 
          AND (cd.cd_marital_status IS NULL OR cd.cd_marital_status <> 'S')
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
item_returns AS (
    SELECT wr_item_sk,
           SUM(wr_return_quantity) AS total_returned,
           SUM(wr_net_loss) AS total_loss
    FROM web_returns
    GROUP BY wr_item_sk
)
SELECT c.c_first_name || ' ' || c.c_last_name AS customer_name,
       c.cd_gender,
       COALESCE(cp.purchase_count, 0) AS purchase_count,
       COALESCE(cp.total_spent, 0.00) AS total_spent,
       ir.total_returned,
       ir.total_loss,
       CASE 
           WHEN ir.total_returned > 0 AND cp.total_spent IS NULL THEN 'No purchases, returned items'
           WHEN ir.total_returned < 0 THEN 'Negative returns'
           ELSE 'No issues'
       END AS return_status,
       RANK() OVER (PARTITION BY c.cd_gender ORDER BY COALESCE(cp.total_spent, 0.00) DESC) AS spending_rank
FROM customer_purchases cp
FULL OUTER JOIN customer c ON cp.c_customer_sk = c.c_customer_sk
LEFT JOIN item_returns ir ON ir.wr_item_sk = cp.w_total_items_bought
WHERE EXISTS (
    SELECT 1
    FROM inventory i
    WHERE i.inv_quantity_on_hand > 0 
          AND i.inv_item_sk = ir.wr_item_sk 
          AND i.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
)
ORDER BY spending_rank, total_spent DESC NULLS LAST
LIMIT 100;
