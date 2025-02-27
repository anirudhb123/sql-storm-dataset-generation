
WITH RECURSIVE sales_rank AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_sales_price DESC) as revenue_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(ws2.ws_sold_date_sk) FROM web_sales ws2)
),
inventory_status AS (
    SELECT 
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    WHERE 
        inv.inv_date_sk = (SELECT MAX(inv2.inv_date_sk) FROM inventory inv2)
    GROUP BY 
        inv.inv_warehouse_sk
),
customer_activity AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY 
        c.c_customer_sk
    HAVING 
        total_orders > 5
)
SELECT 
    ca.c_customer_sk,
    ca.total_orders,
    ca.total_spent,
    COALESCE(ir.total_quantity, 0) AS inventory_on_hand,
    sr.web_name,
    sr.ws_sales_price
FROM 
    customer_activity ca
LEFT JOIN 
    inventory_status ir ON ir.inv_warehouse_sk = ca.c_customer_sk % 10  -- Simulated warehouse association
LEFT JOIN 
    sales_rank sr ON ca.c_customer_sk = sr.web_site_sk
WHERE 
    sr.revenue_rank <= 3
ORDER BY 
    ca.total_spent DESC, 
    sr.ws_sales_price ASC;
