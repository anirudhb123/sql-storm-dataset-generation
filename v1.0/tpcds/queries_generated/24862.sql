
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_ext_sales_price DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2451918 AND 2451928
),
ReturnStats AS (
    SELECT
        sr.returning_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr.return_amt) AS total_return_amt,
        AVG(sr.return_quantity) AS avg_return_quantity
    FROM store_returns sr
    GROUP BY sr.returning_customer_sk
),
SalesVsReturns AS (
    SELECT
        cs.cs_ship_mode_sk,
        cs.cs_order_number,
        COALESCE(SUM(ws_ext_sales_price), 0) AS total_sales,
        COALESCE(rt.total_returns, 0) AS total_returns,
        CASE 
            WHEN COALESCE(rt.total_returns, 0) = 0 THEN NULL 
            ELSE SUM(ws_ext_sales_price) / NULLIF(rt.total_returns, 0) 
        END AS sales_per_return
    FROM catalog_sales cs
    LEFT JOIN RankedSales rs ON cs.cs_order_number = rs.ws_order_number
    LEFT JOIN ReturnStats rt ON cs.cs_ship_mode_sk = rt.returning_customer_sk
    GROUP BY cs.cs_ship_mode_sk, cs.cs_order_number, rt.total_returns
),
FinalReport AS (
    SELECT 
        rv.cs_ship_mode_sk, 
        rv.total_sales, 
        rv.total_returns,
        CASE WHEN rv.sales_per_return IS NULL THEN 'No Returns' ELSE CAST(rv.sales_per_return AS VARCHAR) END AS sales_per_return
    FROM SalesVsReturns rv
    WHERE rv.total_sales > 1000
    UNION ALL
    SELECT 
        sm.sm_ship_mode_sk, 
        0 AS total_sales, 
        0 AS total_returns, 
        'Not Applicable' AS sales_per_return
    FROM ship_mode sm
    WHERE sm.sm_ship_mode_sk NOT IN (SELECT DISTINCT cs.cs_ship_mode_sk FROM catalog_sales cs)
)
SELECT 
    f.cs_ship_mode_sk,
    f.total_sales,
    f.total_returns,
    f.sales_per_return,
    COALESCE(sm.sm_type, 'Unknown') AS shipment_type
FROM FinalReport f
LEFT JOIN ship_mode sm ON f.cs_ship_mode_sk = sm.sm_ship_mode_sk
ORDER BY f.total_sales DESC, sm.sm_type;
