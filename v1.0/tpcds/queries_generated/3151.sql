
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
HighValueCustomers AS (
    SELECT 
        * 
    FROM 
        CustomerStats
    WHERE 
        rank <= 10
),
StoreMetrics AS (
    SELECT 
        ss_store_sk,
        AVG(ss_net_paid) AS avg_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        SUM(ss_net_profit) AS total_store_profit
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
)
SELECT 
    COALESCE(c.c_first_name, 'Unknown') AS customer_first_name,
    COALESCE(c.c_last_name, 'Unknown') AS customer_last_name,
    w.w_warehouse_id AS warehouse_id,
    sm.sm_type AS ship_mode,
    hvc.total_orders,
    hvc.total_profit,
    sm.sm_carrier,
    sm.sm_contract,
    sm.sm_code,
    store_metrics.avg_sales,
    store_metrics.total_transactions,
    store_metrics.total_store_profit
FROM 
    HighValueCustomers hvc
FULL OUTER JOIN 
    warehouse w ON w.w_warehouse_sk = (SELECT TOP 1 w_warehouse_sk FROM inventory WHERE inv_quantity_on_hand > 0 ORDER BY inv_quantity_on_hand DESC)
JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk = (SELECT TOP 1 sm_ship_mode_sk FROM web_sales WHERE ws_ship_customer_sk = hvc.c_customer_sk ORDER BY ws_net_profit DESC)
JOIN 
    StoreMetrics store_metrics ON store_metrics.ss_store_sk = (SELECT TOP 1 ss_store_sk FROM store WHERE s_number_employees > 10 ORDER BY s_number_employees DESC)
ORDER BY 
    hvc.total_profit DESC;
