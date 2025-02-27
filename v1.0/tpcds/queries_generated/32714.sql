
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ws_sold_date_sk
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_sold_date_sk
    UNION ALL
    SELECT 
        ws.ws_item_sk,
        sd.total_quantity + ws.ws_quantity AS total_quantity,
        sd.total_sales + ws.ws_sales_price AS total_sales,
        ws.ws_sold_date_sk
    FROM 
        web_sales ws
    INNER JOIN 
        sales_data sd ON ws.ws_sold_date_sk = sd.ws_sold_date_sk
    WHERE 
        ws.ws_item_sk = sd.ws_item_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
inventory_stats AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    cs.c_customer_id,
    cs.orders_count,
    cs.total_spent,
    COALESCE(sd.total_quantity, 0) AS total_sold_quantity,
    COALESCE(sd.total_sales, 0) AS total_sold_value,
    is.total_inventory
FROM 
    customer_stats cs
LEFT JOIN 
    sales_data sd ON cs.c_customer_id = (
        SELECT c.c_customer_id 
        FROM customer c 
        WHERE c.c_customer_sk = (SELECT DISTINCT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_item_sk IN (SELECT i.i_item_sk FROM item i WHERE i.i_current_price > 50) LIMIT 1) 
    )
LEFT JOIN 
    inventory_stats is ON sd.ws_item_sk = is.inv_item_sk
WHERE 
    cs.total_spent > 100
ORDER BY 
    cs.total_spent DESC;
