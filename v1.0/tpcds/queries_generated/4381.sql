
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TopSales AS (
    SELECT 
        web_site_sk,
        ws_order_number,
        ws_quantity,
        ws_ext_sales_price,
        ws_net_profit
    FROM 
        RankedSales
    WHERE 
        rn <= 10
),
TotalSales AS (
    SELECT 
        w.warehouse_sk,
        SUM(ts.ws_ext_sales_price) AS total_ext_sales_price,
        SUM(ts.ws_net_profit) AS total_net_profit
    FROM 
        TopSales ts
    JOIN 
        warehouse w ON ts.web_site_sk = w.warehouse_sk
    GROUP BY 
        w.warehouse_sk
),
CustomerReturns AS (
    SELECT 
        sr.rc_customer_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(sr.sr_ticket_number) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.rc_customer_sk
),
SalesVsReturns AS (
    SELECT 
        ts.web_site_sk,
        ts.ws_order_number,
        ts.ws_ext_sales_price,
        tr.total_return_amt,
        tr.total_returns,
        CASE 
            WHEN tr.total_return_amt IS NULL THEN 'No Returns'
            WHEN tr.total_return_amt > 0 THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM 
        TopSales ts
    LEFT JOIN 
        CustomerReturns tr ON ts.web_site_sk = tr.rc_customer_sk
)
SELECT 
    s.warehouse_sk,
    SUM(s.ws_ext_sales_price) AS total_sales,
    AVG(s.total_net_profit) AS avg_net_profit,
    COUNT(s.ws_order_number) AS orders_count,
    JSON_OBJECT_AGG(s.return_status, COUNT(s.return_status)) AS return_analysis
FROM 
    SalesVsReturns s
JOIN 
    TotalSales ts ON s.web_site_sk = ts.warehouse_sk
WHERE 
    total_sales > 10000
GROUP BY 
    s.warehouse_sk
ORDER BY 
    total_sales DESC;
