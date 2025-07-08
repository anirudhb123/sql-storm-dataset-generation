
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        1 AS level
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    
    UNION ALL

    SELECT 
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sales_price,
        cs.cs_quantity,
        level + 1
    FROM 
        catalog_sales cs
    JOIN 
        sales_cte s ON cs.cs_order_number = s.ws_order_number
    WHERE 
        s.level < 3
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'N/A') AS gender,
        SUM(CASE 
            WHEN ws.ws_sales_price > 100 THEN ws.ws_quantity 
            ELSE 0 
        END) AS large_purchases,
        COUNT(DISTINCT cs.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        sales_cte cs ON ws.ws_item_sk = cs.ws_item_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
inventory_stats AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        SUM(CASE 
            WHEN inv.inv_quantity_on_hand < 5 THEN 1 
            ELSE 0 
        END) AS low_stock_items
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    cs.c_customer_sk,
    cs.gender,
    cs.large_purchases,
    cs.total_orders,
    inv.total_quantity,
    inv.low_stock_items,
    ROW_NUMBER() OVER (PARTITION BY cs.gender ORDER BY cs.large_purchases DESC) AS rank
FROM 
    customer_stats cs
JOIN 
    inventory_stats inv ON cs.c_customer_sk = inv.inv_item_sk
WHERE 
    inv.total_quantity IS NOT NULL
ORDER BY 
    cs.large_purchases DESC, cs.total_orders ASC
LIMIT 10;
