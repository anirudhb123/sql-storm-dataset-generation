
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(sr.sr_item_sk) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS return_amount,
        AVG(sr.sr_return_quantity) AS avg_return_quantity
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        COUNT(distinct inv.inv_item_sk) AS unique_items_in_stock,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM warehouse w
    JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name
),
SalesStats AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM web_sales ws
    GROUP BY ws.web_site_sk
)

SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    ws.unique_items_in_stock,
    ws.total_quantity_on_hand,
    ss.total_sales,
    ss.total_orders,
    ss.unique_customers
FROM CustomerStats cs
JOIN WarehouseStats ws ON ws.w_warehouse_sk = (SELECT MIN(w.w_warehouse_sk) FROM warehouse w)
JOIN SalesStats ss ON ss.web_site_sk = (SELECT MIN(ws.web_site_sk) FROM web_site ws)
WHERE cs.total_returns > 0
ORDER BY cs.return_amount DESC
LIMIT 50;
