
WITH RECURSIVE Inventory_CTE AS (
    SELECT 
        inv_date_sk, 
        inv_item_sk, 
        inv_warehouse_sk, 
        inv_quantity_on_hand
    FROM 
        inventory
    WHERE 
        inv_quantity_on_hand > 0
    UNION ALL
    SELECT 
        inv.inv_date_sk, 
        inv.inv_item_sk, 
        inv.inv_warehouse_sk, 
        inv.inv_quantity_on_hand + 10
    FROM 
        inventory inv
    INNER JOIN 
        Inventory_CTE cte ON inv.inv_item_sk = cte.inv_item_sk
    WHERE 
        inv.inv_quantity_on_hand < 100
)
, Customer_Stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        coalesce(d.cd_marital_status, 'Unknown') AS marital_status,
        d.cd_gender,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY d.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        d.cd_marital_status IS NOT NULL 
        AND c.c_first_shipto_date_sk IS NOT NULL 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.cd_marital_status, d.cd_gender
), 
Ship_Mode_Stats AS (
    SELECT 
        sm.sm_ship_mode_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_paid) AS average_payment,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        ship_mode sm
    LEFT JOIN 
        web_sales ws ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.marital_status,
    cs.total_profit,
    sms.total_sales,
    sms.average_payment,
    sms.order_count AS ship_mode_order_count,
    ic.inv_quantity_on_hand
FROM 
    Customer_Stats cs
JOIN 
    Ship_Mode_Stats sms ON cs.order_count = sms.order_count
LEFT JOIN 
    Inventory_CTE ic ON ic.inv_item_sk = cs.c_customer_sk
WHERE 
    cs.rank <= 5
ORDER BY 
    cs.total_profit DESC, sms.total_sales DESC;
