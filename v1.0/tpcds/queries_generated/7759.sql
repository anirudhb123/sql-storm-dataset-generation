
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ship_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        w.web_open_date_sk IS NOT NULL AND 
        w.web_close_date_sk IS NULL
),
CustomerReturns AS (
    SELECT 
        wr_refunded_customer_sk,
        SUM(wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_refunded_customer_sk
),
SalesAndReturns AS (
    SELECT 
        cs.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COALESCE(cr.total_return_amount, 0) AS total_returns,
        COALESCE(cr.return_count, 0) AS return_count
    FROM 
        customer cs
    LEFT JOIN 
        web_sales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        CustomerReturns cr ON cs.c_customer_sk = cr.wr_refunded_customer_sk
    GROUP BY 
        cs.c_customer_sk
),
SalesRanked AS (
    SELECT 
        sar.*,
        RANK() OVER (ORDER BY sar.total_sales - sar.total_returns DESC) AS sales_rank
    FROM 
        SalesAndReturns sar
)
SELECT 
    sr.c_customer_sk,
    sr.total_sales,
    sr.total_returns,
    sr.return_count,
    sr.sales_rank
FROM 
    SalesRanked sr
WHERE 
    sr.sales_rank <= 100
ORDER BY 
    sr.sales_rank;
