
WITH RECURSIVE inventory_summary AS (
    SELECT 
        inv_date_sk, 
        inv_item_sk, 
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory
    GROUP BY 
        inv_date_sk, inv_item_sk
    UNION ALL
    SELECT 
        inv_date_sk, 
        inv_item_sk, 
        total_quantity + 1  -- Simulate an adjustment in inventory (could be based on business logic)
    FROM 
        inventory_summary
    WHERE 
        total_quantity < 100
),
customer_orders AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
high_value_customers AS (
    SELECT 
        c.customer_id, 
        co.total_sales,
        co.total_orders,
        cd.cd_gender
    FROM 
        customer_orders co
    JOIN 
        customer c ON co.c_customer_id = c.c_customer_id
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        co.total_sales > 1000
)
SELECT 
    hvc.customer_id,
    hvc.total_sales,
    hvc.total_orders,
    hvc.cd_gender,
    inv.total_quantity,
    CASE 
        WHEN hvc.total_orders > 5 THEN 'Frequent'
        ELSE 'Infrequent'
    END AS order_frequency,
    COALESCE((
        SELECT 
            COUNT(*) 
        FROM 
            catalog_sales cs 
        WHERE 
            cs.cs_bill_customer_sk = hvc.customer_id 
            AND cs.cs_net_profit > 0
    ), 0) AS profit_count
FROM 
    high_value_customers hvc
LEFT JOIN 
    inventory_summary inv ON inv.inv_item_sk = (
        SELECT 
            MIN(i_item_sk) 
        FROM 
            item i
        WHERE 
            i.i_current_price > 0
    )
WHERE 
    hvc.cd_gender IS NOT NULL
ORDER BY 
    hvc.total_sales DESC;
