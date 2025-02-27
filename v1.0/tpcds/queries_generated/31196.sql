
WITH RECURSIVE sale_dates AS (
    SELECT d_date_sk, d_date 
    FROM date_dim 
    WHERE d_year = 2023
    UNION ALL
    SELECT d.d_date_sk, d.d_date 
    FROM date_dim d 
    INNER JOIN sale_dates sd ON d.d_date_sk = sd.d_date_sk + 1 
    WHERE d.d_year = 2023
), customer_purchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM customer c 
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM sale_dates) 
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), high_value_customers AS (
    SELECT 
        cp.c_customer_sk, 
        cp.c_first_name, 
        cp.c_last_name,
        cp.total_spent,
        cp.orders_count,
        RANK() OVER (ORDER BY cp.total_spent DESC) AS customer_rank
    FROM customer_purchases cp
    WHERE cp.total_spent > 1000
), top_inventory AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(ss.ss_quantity) AS total_sold
    FROM item i
    JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
    HAVING SUM(ss.ss_quantity) > 100
), inventory_movement AS (
    SELECT 
        inv.inv_warehouse_sk,
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        COALESCE(total_sold.total_sold, 0) AS total_sold
    FROM inventory inv
    LEFT JOIN (SELECT * FROM top_inventory) total_sold ON inv.inv_item_sk = total_sold.i_item_sk
    WHERE inv.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_spent,
    im.inv_warehouse_sk,
    im.inv_item_sk,
    im.inv_quantity_on_hand,
    im.total_sold,
    CASE 
        WHEN im.inv_quantity_on_hand IS NULL THEN 'Out of stock'
        WHEN im.inv_quantity_on_hand < 10 THEN 'Low stock'
        ELSE 'In stock' 
    END AS stock_status
FROM high_value_customers hvc
JOIN inventory_movement im ON hvc.c_customer_sk = im.inv_warehouse_sk
ORDER BY hvc.total_spent DESC, im.total_sold DESC
LIMIT 10;
