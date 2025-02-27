
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_product_name, i_brand, i_category, 
           CAST(0 AS INTEGER) AS level
    FROM item
    WHERE i_current_price > 50.00
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, i.i_product_name, i.i_brand, i.i_category, 
           ih.level + 1
    FROM item i
    JOIN item_hierarchy ih ON i.i_item_sk = ih.i_item_sk + 1
),
customer_cdemographics AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status,
           cd.cd_education_status, cd.cd_purchase_estimate,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_gender
    FROM customer_demographics cd
),
sales_summary AS (
    SELECT w.ws_order_number, SUM(ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws_item_sk) AS unique_items_sold,
           MAX(ws_sales_price) AS max_price,
           MIN(ws_sales_price) AS min_price
    FROM web_sales w
    GROUP BY w.ws_order_number
),
customer_sales AS (
    SELECT c.c_customer_sk, SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
top_customers AS (
    SELECT c.c_customer_sk, c.c_first_name || ' ' || c.c_last_name AS full_name,
           cs.total_spent
    FROM customer c
    JOIN customer_sales cs ON c.c_customer_sk = cs.c_customer_sk
    ORDER BY cs.total_spent DESC
    LIMIT 10
),
return_summary AS (
    SELECT sr_returned_date_sk,
           SUM(sr_return_amt) AS total_return_amount, 
           COUNT(sr_item_sk) AS total_returns
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_returned_date_sk
)
SELECT ic.i_item_id, ic.i_product_name, 
       cd_gender, cd_marital_status, 
       COALESCE(ss.total_sales, 0) AS total_sales,
       COALESCE(rs.total_return_amount, 0) AS total_return_amount,
       tc.full_name, tc.total_spent
FROM item_hierarchy ic
LEFT JOIN customer_cdemographics cd ON cd.rank_gender = 1
LEFT JOIN sales_summary ss ON ss.ws_order_number = ic.i_item_sk
LEFT JOIN return_summary rs ON rs.sr_returned_date_sk = ic.i_item_sk
LEFT JOIN top_customers tc ON tc.c_customer_sk = cd.cd_demo_sk
WHERE ic.level = 0 AND cd.cd_marital_status IS NOT NULL
ORDER BY total_sales DESC, total_return_amount ASC;
