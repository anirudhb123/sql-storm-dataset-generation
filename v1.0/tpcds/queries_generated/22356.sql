
WITH Recent_Customers AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_birth_month,
           ROW_NUMBER() OVER (PARTITION BY c_birth_month ORDER BY c_customer_sk DESC) AS rn
    FROM customer
    WHERE c_first_shipto_date_sk IS NOT NULL
),
Sales_Summary AS (
    SELECT ws_bill_customer_sk, 
           SUM(ws_net_paid_inc_tax) AS total_sales,
           COUNT(ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk > (
        SELECT MAX(d_date_sk) 
        FROM date_dim 
        WHERE d_month_seq = (SELECT MAX(d_month_seq) FROM date_dim WHERE d_year = 2023)
    )
    GROUP BY ws_bill_customer_sk
),
Inventory_Levels AS (
    SELECT inv_item_sk, 
           SUM(inv_quantity_on_hand) AS total_quantity
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT rc.c_first_name, rc.c_last_name, rc.c_birth_month,
       ss.total_sales, ss.total_orders,
       COALESCE(il.total_quantity, 0) AS available_stock,
       CASE 
           WHEN ss.total_sales > 10000 THEN 'High Value Customer'
           WHEN ss.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value Customer'
           ELSE 'Low Value Customer'
       END AS customer_category,
       (SELECT COUNT(DISTINCT ws_item_sk) 
        FROM web_sales 
        WHERE ws_bill_customer_sk = rc.c_customer_sk) AS distinct_items_purchased
FROM Recent_Customers rc
LEFT OUTER JOIN Sales_Summary ss ON rc.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN Inventory_Levels il ON il.inv_item_sk IN (
    SELECT distinct ws_item_sk
    FROM web_sales
    WHERE ws_bill_customer_sk = rc.c_customer_sk
    )
WHERE rc.rn = 1
  AND (rc.c_birth_month IS NOT NULL OR rc.c_last_name LIKE '%son')
ORDER BY rc.c_birth_month DESC, ss.total_sales DESC
LIMIT 100;
