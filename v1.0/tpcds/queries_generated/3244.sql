
WITH RankedSales AS (
    SELECT 
        ss.store_sk, 
        ss.sales_price, 
        ss.ext_sales_price, 
        ss.ext_tax, 
        ROW_NUMBER() OVER (PARTITION BY ss.store_sk ORDER BY ss_sales_price DESC) AS sales_rank
    FROM 
        store_sales ss
    WHERE 
        ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
CustomerReturns AS (
    SELECT 
        sr.store_sk, 
        SUM(sr.return_amt) AS total_return_amt,
        COUNT(sr.ticket_number) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.store_sk
),
SalesReturns AS (
    SELECT 
        r.store_sk,
        SUM(r.return_amt) AS return_sales,
        COUNT(r.ticket_number) AS return_count
    FROM (
        SELECT 
            ws.store_sk, 
            ws.net_paid - ws.ext_discount_amt AS return_amt,
            ws.order_number AS ticket_number
        FROM 
            web_sales ws
        WHERE 
            ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
        UNION ALL
        SELECT 
            cs.store_sk,
            cs.net_paid - cs.ext_discount_amt AS return_amt,
            cs.order_number AS ticket_number
        FROM 
            catalog_sales cs
        WHERE 
            cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    ) r
    GROUP BY 
        r.store_sk
)

SELECT 
    s.store_sk,
    COALESCE(rs.sales_price, 0) AS max_sales_price,
    COALESCE(cr.total_return_amt, 0) AS total_return_amount,
    COALESCE(sr.return_sales, 0) AS return_sales,
    COALESCE(rs.ext_sales_price, 0) - COALESCE(cr.total_return_amt, 0) AS net_sales,
    CASE 
        WHEN COALESCE(cr.total_returns, 0) > 0 THEN 'Returns Present'
        ELSE 'No Returns'
    END AS return_status
FROM 
    RankedSales rs
FULL OUTER JOIN CustomerReturns cr ON rs.store_sk = cr.store_sk
FULL OUTER JOIN SalesReturns sr ON rs.store_sk = sr.store_sk
WHERE 
    rs.sales_rank = 1
ORDER BY 
    net_sales DESC;
