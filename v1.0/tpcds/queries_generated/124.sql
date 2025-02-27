
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = CURRENT_DATE - INTERVAL '30 days')
), 
CustomerRanks AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        DENSE_RANK() OVER (PARTITION BY cd.cd_income_band_sk ORDER BY cd.cd_purchase_estimate DESC) AS income_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
WarehouseSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        w.w_warehouse_id
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY ws.ws_item_sk, w.w_warehouse_id
)
SELECT 
    cr.c_first_name,
    cr.c_last_name,
    cr.cd_gender,
    cr.income_rank,
    w.total_net_profit,
    COALESCE(SUM(CASE WHEN ws.rn = 1 THEN ws.ws_quantity END), 0) AS latest_sales_quantity
FROM CustomerRanks cr
LEFT JOIN WarehouseSales w ON w.ws_item_sk IN (SELECT DISTINCT ws_item_sk FROM RankedSales WHERE rn = 1)
LEFT JOIN RankedSales ws ON ws.ws_item_sk = w.ws_item_sk
GROUP BY 
    cr.c_first_name, 
    cr.c_last_name, 
    cr.cd_gender, 
    cr.income_rank, 
    w.total_net_profit
ORDER BY 
    total_net_profit DESC, 
    income_rank;
