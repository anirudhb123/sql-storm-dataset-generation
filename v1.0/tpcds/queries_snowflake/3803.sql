
WITH customer_orders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS spending_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        co.c_customer_sk,
        co.c_first_name,
        co.c_last_name,
        co.total_spent,
        co.order_count
    FROM 
        customer_orders co
    WHERE 
        co.spending_rank <= 10
),
inventory_details AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        item i
    JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE 
        inv.inv_quantity_on_hand > 0
    GROUP BY 
        i.i_item_sk, i.i_product_name
)
SELECT 
    tc.c_customer_sk,
    CONCAT(tc.c_first_name, ' ', tc.c_last_name) AS full_name,
    tc.total_spent,
    tc.order_count,
    id.i_item_sk,
    id.i_product_name,
    id.total_inventory
FROM 
    top_customers tc
CROSS JOIN 
    inventory_details id
LEFT JOIN 
    store_sales ss ON ss.ss_item_sk = id.i_item_sk AND ss.ss_customer_sk = tc.c_customer_sk
WHERE 
    tc.total_spent > (SELECT AVG(total_spent) FROM customer_orders)
ORDER BY 
    tc.total_spent DESC, id.total_inventory ASC
LIMIT 50;
