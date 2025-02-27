
WITH RECURSIVE DateRange AS (
    SELECT MIN(d_date_sk) AS start_date_sk, MAX(d_date_sk) AS end_date_sk
    FROM date_dim
), FilteredCustomers AS (
    SELECT c.c_customer_sk, c.c_customer_id, 
        cd.cd_gender, cd.cd_marital_status, 
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    WHERE cd.cd_purchase_estimate BETWEEN 100 AND 1000
    GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status
), WarehouseStats AS (
    SELECT w.w_warehouse_sk, w.w_warehouse_id,
        COUNT(DISTINCT sr.sr_item_sk) AS distinct_items_returned,
        SUM(sr.sr_return_qty) AS total_qty_returned,
        AVG(sr.sr_return_amt) AS avg_return_amt
    FROM warehouse w
    JOIN store_returns sr ON sr.sr_store_sk = w.w_warehouse_sk
    WHERE w.w_country = 'USA'
    GROUP BY w.w_warehouse_sk, w.w_warehouse_id
), CTE_ShipMode AS (
    SELECT sm.sm_ship_mode_id, sm.sm_code,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM ship_mode sm
    JOIN web_sales ws ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT start_date_sk FROM DateRange) AND (SELECT end_date_sk FROM DateRange)
    GROUP BY sm.sm_ship_mode_id, sm.sm_code
)
SELECT f.c_customer_id, 
    f.cd_gender, 
    f.cd_marital_status, 
    ws.w_warehouse_id, 
    ws.distinct_items_returned, 
    ws.total_qty_returned, 
    ws.avg_return_amt,
    ss.ss_ext_sales_price,
    CASE 
        WHEN f.total_returns > 0 THEN 'Has Returns' 
        ELSE 'No Returns' 
    END AS return_status,
    ROW_NUMBER() OVER (PARTITION BY f.cd_gender ORDER BY f.total_return_amt DESC) AS gender_rank,
    COALESCE(ship.avg_net_profit, 0) AS average_net_profit
FROM FilteredCustomers f
JOIN WarehouseStats ws ON f.c_customer_sk = ws.w_warehouse_sk
LEFT JOIN CTE_ShipMode ship ON f.c_customer_id = ship.sm_ship_mode_id
WHERE (f.cd_marital_status = 'M' AND f.total_returns < 5)
   OR (f.cd_marital_status = 'S' AND f.total_returns >= 5)
ORDER BY f.cd_gender, f.cd_marital_status, f.total_return_amt DESC
FETCH FIRST 100 ROWS ONLY;
