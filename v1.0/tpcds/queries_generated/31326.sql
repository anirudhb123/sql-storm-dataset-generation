
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 100
),
inventory_summary AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT inv.inv_warehouse_sk) AS warehouse_count
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    c.c_customer_sk,
    cs.total_orders,
    cs.total_spent,
    COALESCE(SUM(i.total_quantity), 0) AS total_inventory,
    MAX(s.rn) AS max_web_sales_rank
FROM 
    customer_summary cs
JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    inventory_summary i ON i.inv_item_sk IN (SELECT ws_item_sk FROM sales_cte)
LEFT JOIN 
    sales_cte s ON s.ws_item_sk = i.inv_item_sk
WHERE 
    cs.total_spent > 500
GROUP BY 
    c.c_customer_sk, cs.total_orders, cs.total_spent
HAVING 
    MAX(s.rn) IS NOT NULL OR total_inventory > 50
ORDER BY 
    total_spent DESC
LIMIT 10;
