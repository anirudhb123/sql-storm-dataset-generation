
WITH RECURSIVE DateInventory AS (
    SELECT d.d_date_sk, d.d_date, d.d_year, inv.inv_item_sk, inv.inv_quantity_on_hand
    FROM date_dim d
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year >= 2020
    UNION ALL
    SELECT d.d_date_sk, d.d_date, d.d_year, inv.inv_item_sk, inv.inv_quantity_on_hand
    FROM date_dim d
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN DateInventory di ON d.d_year = di.d_year - 1 AND inv.inv_item_sk = di.inv_item_sk
),
CustomerReturns AS (
    SELECT sr_returned_date_sk, sr_item_sk, sr_return_quantity, sr_return_amt_inc_tax
    FROM store_returns 
    WHERE sr_return_quantity > 0
),
SalesData AS (
    SELECT ws.ws_sold_date_sk, ws.ws_item_sk, SUM(ws.ws_quantity) AS total_sold,
           SUM(ws.ws_net_paid_inc_tax) AS total_revenue
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
WarehouseSummary AS (
    SELECT w.w_warehouse_sk, w.w_warehouse_id, SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM warehouse w
    JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_warehouse_id
),
FinalSummary AS (
    SELECT di.d_year, di.inv_item_sk,
           COALESCE(SUM(CASE WHEN cr.sr_item_sk IS NOT NULL THEN cr.sr_return_quantity END), 0) AS total_returns,
           COALESCE(SUM(sd.total_sold), 0) AS total_sales,
           COALESCE(SUM(sd.total_revenue), 0) AS total_revenue,
           COALESCE(SUM(sd.total_revenue) - CASE WHEN COALESCE(SUM(CASE WHEN cr.sr_item_sk IS NOT NULL THEN cr.sr_return_quantity END), 0) > 0 THEN COALESCE(SUM(CASE WHEN cr.sr_item_sk IS NOT NULL THEN cr.sr_return_quantity END), 0) ELSE 0 END, 0) AS net_revenue,
           ws.total_inventory
    FROM DateInventory di
    LEFT JOIN CustomerReturns cr ON di.inv_item_sk = cr.sr_item_sk
    LEFT JOIN SalesData sd ON di.d_date_sk = sd.ws_sold_date_sk AND di.inv_item_sk = sd.ws_item_sk
    JOIN WarehouseSummary ws ON ws.total_inventory > 0
    GROUP BY di.d_year, di.inv_item_sk, ws.total_inventory
)
SELECT f.d_year, f.inv_item_sk, f.total_returns, f.total_sales, f.total_revenue, f.net_revenue, 
       CASE 
           WHEN f.total_revenue >= 0 THEN 'Profitable' 
           ELSE 'Loss' 
       END AS profit_status
FROM FinalSummary f
WHERE f.total_returns IS NOT NULL OR f.total_sales IS NOT NULL
ORDER BY f.d_year, f.inv_item_sk;
