
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) as rank
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_country = 'USA' AND ws.ws_ext_sales_price > 0
),
ReturnsSummary AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_returned_date_sk) AS return_days
    FROM store_returns
    GROUP BY sr_item_sk
),
FilteredInventories AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS available_stock
    FROM inventory inv
    JOIN warehouse wa ON inv.inv_warehouse_sk = wa.w_warehouse_sk
    WHERE wa.w_country IS NOT NULL
    GROUP BY inv.inv_item_sk
),
SalesAndReturns AS (
    SELECT 
        rs.web_site_sk,
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_ext_sales_price,
        rs.ws_net_profit,
        COALESCE(rs_rank, 0) AS rank,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(fi.available_stock, 0) AS available_stock
    FROM RankedSales rs
    LEFT JOIN ReturnsSummary rs ON rs.ws_item_sk = rs.sr_item_sk
    LEFT JOIN FilteredInventories fi ON rs.ws_item_sk = fi.inv_item_sk
)
SELECT 
    w.web_site_name,
    COUNT(DISTINCT ss.ws_order_number) AS total_orders,
    SUM(ss.ws_net_profit) AS total_profit,
    AVG(ss.available_stock) AS avg_stock_available,
    COUNT(DISTINCT CASE WHEN ss.total_returns > 0 THEN ss.ws_order_number END) AS orders_with_returns
FROM SalesAndReturns ss
JOIN web_site w ON ss.web_site_sk = w.web_site_sk
WHERE ss.rank = 1
GROUP BY w.web_site_name
HAVING SUM(ss.ws_net_profit) > (SELECT AVG(ws.ws_net_profit) FROM web_sales ws) 
   OR AVG(ss.available_stock) < (SELECT AVG(inv.inv_quantity_on_hand) FROM inventory inv WHERE inv.inv_quantity_on_hand IS NOT NULL)
ORDER BY total_profit DESC;

```
