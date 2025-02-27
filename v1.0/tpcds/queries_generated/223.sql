
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN income_band ib ON cd.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE 
        c.c_birth_year IS NOT NULL
        AND (cd.cd_gender = 'M' OR cd.cd_marital_status = 'M')
        AND ws.ws_sold_date_sk = (
            SELECT MAX(ws_sub.ws_sold_date_sk)
            FROM web_sales ws_sub
            WHERE ws_sub.ws_ship_mode_sk = ws.ws_ship_mode_sk
        )
    GROUP BY 
        ws.web_site_id
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT ws.ws_order_number) as total_orders,
        AVG(ws.ws_net_paid) AS avg_net_paid
    FROM 
        warehouse w
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
CustomerReturns AS (
    SELECT 
        ws.ws_web_site_sk,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_returns,
        SUM(COALESCE(sr_return_amt, 0)) AS total_return_amount
    FROM 
        web_sales ws
    LEFT JOIN store_returns sr ON ws.ws_item_sk = sr.sr_item_sk AND ws.ws_order_number = sr.sr_ticket_number
    GROUP BY 
        ws.ws_web_site_sk
)
SELECT 
    ss.web_site_id,
    ss.total_quantity,
    ss.total_profit,
    ws.total_orders,
    ws.avg_net_paid,
    cr.total_returns,
    cr.total_return_amount
FROM 
    SalesSummary ss
LEFT JOIN WarehouseStats ws ON ss.web_site_id = ws.w_warehouse_id
LEFT JOIN CustomerReturns cr ON ss.web_site_id = cr.ws_web_site_sk
WHERE 
    ss.total_quantity > 100
ORDER BY 
    ss.total_profit DESC, ws.avg_net_paid DESC
LIMIT 10;
