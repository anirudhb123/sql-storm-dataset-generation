
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
inventory_status AS (
    SELECT 
        inv.inv_item_sk,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_inventory,
        CASE 
            WHEN SUM(inv.inv_quantity_on_hand) IS NULL THEN 'No Inventory'
            WHEN SUM(inv.inv_quantity_on_hand) < 10 THEN 'Low Stock'
            ELSE 'Sufficient Stock'
        END AS stock_status
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws_order_number) AS orders_count,
        AVG(ws_sales_price) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cs.c_customer_sk AS customer_id,
    cs.orders_count,
    cs.avg_order_value,
    ss.total_quantity,
    ss.total_sales,
    is.total_inventory,
    is.stock_status
FROM 
    customer_info cs
LEFT JOIN 
    sales_summary ss ON cs.orders_count > 0 AND ss.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_ship_customer_sk = cs.c_customer_sk)
LEFT JOIN 
    inventory_status is ON ss.ws_item_sk = is.inv_item_sk
WHERE 
    cs.orders_count > 5
    AND (cs.avg_order_value > 100 OR cs.cd_gender = 'F')
ORDER BY 
    cs.avg_order_value DESC;
