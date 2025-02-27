
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number
),
TopSales AS (
    SELECT 
        r.web_site_sk,
        r.ws_order_number,
        r.total_sales,
        r.sales_rank
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 10
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(*) AS return_count,
        SUM(wr_return_amt) AS total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(cr.return_count, 0) AS return_count,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    CASE 
        WHEN COALESCE(ts.total_sales, 0) = 0 THEN 'Never Bought'
        WHEN COALESCE(cr.return_count, 0) > 0 THEN 'Returned'
        ELSE 'Active'
    END AS customer_status
FROM 
    customer c
LEFT JOIN 
    TopSales ts ON c.c_customer_sk = ts.ws_order_number
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
WHERE 
    c.c_current_cdemo_sk IS NOT NULL
ORDER BY 
    c.c_customer_id;
