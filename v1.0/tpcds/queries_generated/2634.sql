
WITH sales_summary AS (
    SELECT 
        ws.sold_date_sk,
        ws.item_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        AVG(ws.net_profit) AS avg_net_profit,
        COUNT(ws.order_number) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk BETWEEN 1 AND 1000
    GROUP BY 
        ws.sold_date_sk, ws.item_sk
),
customer_info AS (
    SELECT 
        c.customer_sk,
        cd.gender,
        cd.marital_status,
        hd.income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.gender ORDER BY c.customer_id) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
    LEFT JOIN 
        household_demographics hd ON c.current_hdemo_sk = hd.demo_sk
),
inventory_levels AS (
    SELECT 
        i.item_sk,
        COALESCE(SUM(inv.quantity_on_hand), 0) AS total_inventory
    FROM 
        item i
    LEFT JOIN 
        inventory inv ON i.item_sk = inv.inv_item_sk
    GROUP BY 
        i.item_sk
)
SELECT 
    ci.customer_sk,
    ci.gender,
    ci.marital_status,
    ss.total_sales,
    ss.avg_net_profit,
    il.total_inventory
FROM 
    customer_info ci
JOIN 
    sales_summary ss ON ci.customer_sk = ss.item_sk
JOIN 
    inventory_levels il ON ss.item_sk = il.item_sk
WHERE 
    ci.income_band_sk IS NOT NULL 
    AND (ss.total_sales > 1000 OR ss.avg_net_profit IS NULL)
ORDER BY 
    ss.total_sales DESC
LIMIT 50;
