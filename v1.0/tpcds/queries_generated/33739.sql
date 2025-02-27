
WITH RECURSIVE inventory_levels AS (
    SELECT inv_date_sk, inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    UNION ALL
    SELECT il.inv_date_sk, il.inv_item_sk, il.inv_warehouse_sk, il.inv_quantity_on_hand - 10
    FROM inventory_levels il
    WHERE il.inv_quantity_on_hand - 10 >= 0
), 
customer_purchases AS (
    SELECT c.c_customer_sk, SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
high_value_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cp.total_sales
    FROM customer c
    JOIN customer_purchases cp ON c.c_customer_sk = cp.c_customer_sk
    WHERE cp.total_sales > (SELECT AVG(total_sales) FROM customer_purchases)
),
product_sales AS (
    SELECT i.i_item_sk, SUM(ws.ws_quantity) AS total_quantity_sold, 
           AVG(ws.ws_sales_price) AS avg_sales_price
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk
),
inventory_summary AS (
    SELECT il.inv_item_sk, SUM(il.inv_quantity_on_hand) AS total_inventory
    FROM inventory_levels il
    GROUP BY il.inv_item_sk
)
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    hvc.total_sales, 
    ps.total_quantity_sold, 
    ps.avg_sales_price, 
    COALESCE(inv.total_inventory, 0) AS total_inventory
FROM high_value_customers hvc
LEFT JOIN product_sales ps ON ps.i_item_sk = hvc.c_customer_sk
LEFT JOIN inventory_summary inv ON inv.inv_item_sk = ps.i_item_sk
WHERE hvc.total_sales IS NOT NULL
    AND (hvc.total_sales > 1000 OR inv.total_inventory> 0)
ORDER BY hvc.total_sales DESC;
