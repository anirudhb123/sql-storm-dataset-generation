
WITH RECURSIVE inventory_summary AS (
    SELECT 
        inv_date_sk,
        inv_item_sk,
        inv_warehouse_sk,
        inv_quantity_on_hand,
        1 AS level
    FROM 
        inventory
    WHERE 
        inv_quantity_on_hand > 0
    UNION ALL
    SELECT 
        inv_date_sk,
        inv_item_sk,
        inv_warehouse_sk,
        inv_quantity_on_hand - 1,
        level + 1
    FROM 
        inventory_summary
    WHERE 
        inv_quantity_on_hand > 1
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_store_returns
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN 
        store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
sales_summary AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        w.w_warehouse_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.income_band_sk,
    COALESCE(ss.total_sales, 0) AS total_sales_warehouse,
    COALESCE(ss.total_quantity, 0) AS total_quantity_warehouse,
    ss.total_orders,
    (SELECT COUNT(*) FROM inventory_summary isum WHERE isum.inv_item_sk IN (SELECT i.i_item_sk FROM item i WHERE i.i_current_price > 20.00)) AS high_value_inventory_count
FROM
    customer_summary cs
LEFT JOIN 
    sales_summary ss ON cs.c_customer_sk = ss.w_warehouse_sk
WHERE 
    cs.total_store_returns > 5
ORDER BY 
    cs.c_last_name, cs.c_first_name;
