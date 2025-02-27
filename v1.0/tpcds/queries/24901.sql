
WITH RECURSIVE date_series AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_date = (SELECT MAX(d_date) FROM date_dim)
    UNION ALL
    SELECT d.d_date_sk, d.d_date
    FROM date_dim d
    JOIN date_series ds ON d.d_date_sk = ds.d_date_sk - 1
),
updated_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
           cd.cd_gender, 
           CASE 
               WHEN cd.cd_marital_status IS NULL THEN 'Unknown'
               ELSE cd.cd_marital_status 
           END AS marital_status,
           cd.cd_purchase_estimate, 
           COALESCE(cd.cd_dep_count, 0) AS dep_count,
           COALESCE(cd.cd_dep_employed_count, 0) AS employed_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
inventory_status AS (
    SELECT inv.inv_item_sk, sum(inv.inv_quantity_on_hand) AS total_quantity,
           CASE
               WHEN SUM(inv.inv_quantity_on_hand) IS NULL THEN 'No Stock'
               WHEN SUM(inv.inv_quantity_on_hand) < 10 THEN 'Low Stock'
               ELSE 'In Stock'
           END AS stock_status
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
sales_info AS (
    SELECT ws.ws_item_sk,
           COUNT(ws.ws_order_number) AS total_orders,
           SUM(ws.ws_sales_price) AS total_sales,
           AVG(ws.ws_sales_price) AS avg_sales_price
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_series)
    GROUP BY ws.ws_item_sk
)
SELECT c.full_name, 
       c.marital_status,
       c.dep_count,
       item.i_item_id,
       item.i_product_name,
       COALESCE(inv.total_quantity, 0) AS inventory_quantity,
       inv.stock_status,
       COALESCE(s.total_orders, 0) AS total_orders,
       COALESCE(s.total_sales, 0) AS total_sales,
       CASE 
           WHEN c.cd_gender = 'F' AND s.total_sales > 1000 THEN 'High Value Female'
           WHEN c.cd_gender = 'M' AND s.total_sales > 1000 THEN 'High Value Male'
           ELSE 'Regular Customer'
       END AS customer_type
FROM updated_customers c
LEFT JOIN item ON c.c_customer_sk = item.i_item_sk
LEFT JOIN inventory_status inv ON item.i_item_sk = inv.inv_item_sk
LEFT JOIN sales_info s ON item.i_item_sk = s.ws_item_sk
ORDER BY customer_type, total_sales DESC
LIMIT 50;
