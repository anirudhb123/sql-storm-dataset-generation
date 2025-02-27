
WITH RECURSIVE sales_ranking AS (
    SELECT ws_item_sk, 
           SUM(ws_sales_price) AS total_sales,
           RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank_sales
    FROM web_sales
    GROUP BY ws_item_sk
),
store_rank AS (
    SELECT ss_store_sk, 
           SUM(ss_net_paid) AS total_net_paid,
           RANK() OVER (ORDER BY SUM(ss_net_paid) DESC) AS store_rank
    FROM store_sales
    GROUP BY ss_store_sk
),
inventory_status AS (
    SELECT inv_item_sk, 
           SUM(inv_quantity_on_hand) AS total_stock,
           CASE 
               WHEN SUM(inv_quantity_on_hand) = 0 THEN 'Out of Stock'
               WHEN SUM(inv_quantity_on_hand) < 50 THEN 'Low Stock'
               ELSE 'In Stock'
           END AS stock_status
    FROM inventory
    GROUP BY inv_item_sk
),
customer_ranking AS (
    SELECT c_customer_sk,
           cd_gender,
           COUNT(DISTINCT ws_order_number) AS order_count,
           RANK() OVER (PARTITION BY cd_gender ORDER BY COUNT(DISTINCT ws_order_number) DESC) AS gender_rank
    FROM customer
    LEFT JOIN web_sales ON c_customer_sk = ws_bill_customer_sk
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY c_customer_sk, cd_gender
)
SELECT i.i_item_id,
       COALESCE(wsr.total_sales, 0) AS web_sales_total,
       COALESCE(ssr.total_net_paid, 0) AS store_sales_total,
       is.total_stock,
       is.stock_status,
       cr.customer_count AS top_customers,
       cr.gender_rank
FROM item i
LEFT JOIN sales_ranking wsr ON i.i_item_sk = wsr.ws_item_sk
LEFT JOIN store_rank ssr ON ssr.store_rank = 1 
LEFT JOIN inventory_status is ON i.i_item_sk = is.inv_item_sk
LEFT JOIN (
    SELECT cd_gender, 
           COUNT(*) AS customer_count,
           MIN(gender_rank) AS gender_rank
    FROM customer_ranking
    WHERE order_count > 5
    GROUP BY cd_gender
) cr ON 1 = 1 
WHERE (is.stock_status IS NOT NULL OR cr.gender_rank IS NOT NULL)
ORDER BY i.i_item_id, 
         wsr.total_sales DESC, 
         ssr.total_net_paid DESC;
