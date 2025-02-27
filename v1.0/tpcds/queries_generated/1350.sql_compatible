
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_sk, ws.web_id
),
TopSales AS (
    SELECT 
        rs.web_site_sk,
        rs.web_id,
        rs.total_orders,
        rs.total_sales
    FROM RankedSales rs
    WHERE rs.sales_rank <= 5
),
CustomerReturns AS (
    SELECT 
        sr_cdemo_sk, 
        SUM(sr_return_amt) AS total_returned,
        COUNT(sr_return_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_cdemo_sk
),
ReturnAnalysis AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_income_band_sk,
        COALESCE(cr.total_returned, 0) AS total_returned,
        COALESCE(cr.return_count, 0) AS return_count
    FROM customer_demographics cd
    LEFT JOIN CustomerReturns cr ON cd.cd_demo_sk = cr.sr_cdemo_sk
)
SELECT 
    ts.web_id,
    ts.total_orders,
    ts.total_sales,
    ra.cd_gender,
    ra.total_returned,
    ra.return_count
FROM TopSales ts
JOIN ReturnAnalysis ra ON ts.web_site_sk = ra.cd_demo_sk
WHERE ra.total_returned > 0
ORDER BY ts.total_sales DESC, ra.return_count ASC;
