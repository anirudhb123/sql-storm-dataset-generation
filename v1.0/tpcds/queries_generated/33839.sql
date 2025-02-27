
WITH RECURSIVE DateHierarchy AS (
    SELECT d_date_sk, d_date, d_year
    FROM date_dim
    WHERE d_year >= 2020
    UNION ALL
    SELECT d.d_date_sk, d.d_date, d.d_year
    FROM date_dim d
    INNER JOIN DateHierarchy dh ON d.d_year = dh.d_year + 1
),
CustomerReturns AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        COUNT(DISTINCT cr.cr_order_number) AS return_orders
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
),
ItemSales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        COUNT(DISTINCT ws.ws_order_number) AS sales_orders
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk IN (SELECT d_date_sk FROM DateHierarchy)
    GROUP BY ws.ws_item_sk
),
SalesReturns AS (
    SELECT 
        is.ws_item_sk,
        is.total_sold,
        COALESCE(cr.total_returned, 0) AS total_returned,
        (is.total_sold - COALESCE(cr.total_returned, 0)) AS net_sales
    FROM ItemSales is
    LEFT JOIN CustomerReturns cr ON is.ws_item_sk = cr.cr_item_sk
),
WarehouseData AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM warehouse w
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_id, w.w_warehouse_name
)
SELECT 
    st.ws_item_sk,
    COALESCE(w.total_orders, 0) AS total_orders,
    COALESCE(w.total_profit, 0) AS total_profit,
    st.total_sold,
    st.total_returned,
    st.net_sales,
    CASE 
        WHEN st.net_sales > 1000 THEN 'High Performer'
        WHEN st.net_sales BETWEEN 500 AND 1000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM SalesReturns st
LEFT JOIN WarehouseData w ON st.ws_item_sk IN (
    SELECT ws.ws_item_sk
    FROM web_sales ws
    WHERE ws.ws_item_sk = st.ws_item_sk
)
WHERE st.net_sales > 0
ORDER BY st.net_sales DESC;
