
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 0 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON c.c_current_cdemo_sk = ch.c_customer_sk
),
sales_data AS (
    SELECT ws.ws_bill_customer_sk, SUM(ws.ws_sales_price) AS total_sales, COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 1000 AND 1500
    GROUP BY ws.ws_bill_customer_sk
),
avg_sales AS (
    SELECT ws_bill_customer_sk, AVG(total_sales) AS avg_sales_per_customer
    FROM sales_data
    GROUP BY ws_bill_customer_sk
),
high_value_customers AS (
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, avg.avg_sales_per_customer
    FROM customer_hierarchy ch
    JOIN avg_sales avg ON ch.c_customer_sk = avg.ws_bill_customer_sk
    WHERE avg.avg_sales_per_customer > (SELECT AVG(avg_sales_per_customer) FROM avg_sales)
),
inventory_data AS (
    SELECT inv.inv_item_sk, SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM inventory inv
    GROUP BY inv.inv_item_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(sd.total_sales, 0) AS total_web_sales,
    i.total_quantity AS total_inventory,
    CASE WHEN sd.total_orders IS NULL THEN 'No Orders' ELSE 'Has Orders' END AS order_status
FROM customer c
LEFT JOIN sales_data sd ON c.c_customer_sk = sd.ws_bill_customer_sk
JOIN inventory_data i ON i.inv_item_sk IN (SELECT DISTINCT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk)
WHERE c.c_customer_sk IN (SELECT c_customer_sk FROM high_value_customers)
ORDER BY total_web_sales DESC, c.c_last_name ASC;
