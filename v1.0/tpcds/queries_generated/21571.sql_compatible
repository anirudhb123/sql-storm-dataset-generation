
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
),
high_value_orders AS (
    SELECT 
        ws_order_number,
        SUM(ws_sales_price * ws_quantity) AS total_order_value,
        COUNT(DISTINCT ws_item_sk) AS item_count
    FROM 
        web_sales
    GROUP BY 
        ws_order_number
    HAVING 
        SUM(ws_sales_price * ws_quantity) > 1000
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(ws_ext_sales_price) IS NOT NULL AND COUNT(DISTINCT ws_order_number) > 10
),
inventory_status AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    c.c_customer_id,
    t.total_spent,
    h.total_order_value,
    i.total_quantity,
    CASE 
        WHEN i.total_quantity IS NULL THEN 'Out of Stock'
        WHEN i.total_quantity < 10 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status
FROM 
    top_customers t
JOIN 
    high_value_orders h ON t.total_orders > 5
LEFT JOIN 
    inventory_status i ON i.inv_item_sk = (SELECT ws_item_sk FROM ranked_sales WHERE price_rank = 1 AND ws_order_number = h.ws_order_number)
WHERE 
    EXISTS (
        SELECT 1 
        FROM ranked_sales rs 
        WHERE rs.ws_item_sk = i.inv_item_sk AND rs.ws_order_number = h.ws_order_number
    )
AND 
    t.total_spent > (SELECT AVG(total_spent) FROM top_customers) 
ORDER BY 
    t.total_spent DESC;
