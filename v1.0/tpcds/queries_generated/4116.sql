
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws.ws_shipped_date_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_shipped_date_sk
),
inventory_check AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    ss.total_quantity_sold,
    ss.total_sales_amount,
    ic.total_inventory,
    COALESCE(ss.total_orders, 0) AS total_orders
FROM 
    customer_stats cs
LEFT JOIN 
    sales_summary ss ON cs.c_customer_sk = ss.ws_shipped_date_sk
LEFT JOIN 
    inventory_check ic ON cs.c_customer_sk = ic.inv_item_sk
WHERE 
    cs.rn <= 10 
    AND (cs.cd_gender = 'F' OR cs.cd_marital_status = 'M')
ORDER BY 
    ss.total_sales_amount DESC NULLS LAST;
