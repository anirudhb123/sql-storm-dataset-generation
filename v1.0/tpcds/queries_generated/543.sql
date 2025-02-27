
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
), 

CustomerReturns AS (
    SELECT 
        wr.wr_returning_customer_sk, 
        SUM(wr.wr_return_quantity) AS total_returned
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk IN (
            SELECT 
                ws.ws_sold_date_sk 
            FROM 
                web_sales ws 
            WHERE 
                ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
            GROUP BY 
                ws.ws_sold_date_sk
        )
    GROUP BY 
        wr.wr_returning_customer_sk
), 

SalesAndReturns AS (
    SELECT 
        cs.c_customer_id,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales,
        COALESCE(SUM(cr.total_returned), 0) AS total_returns
    FROM 
        customer cs
    LEFT JOIN 
        web_sales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        CustomerReturns cr ON cs.c_customer_sk = cr.wr_returning_customer_sk
    GROUP BY 
        cs.c_customer_id
)

SELECT 
    s.web_site_id,
    s.total_sales,
    r.total_returns,
    (s.total_sales - r.total_returns) AS net_sales,
    CASE 
        WHEN r.total_returns > 0 THEN (r.total_returns::decimal / NULLIF(s.total_sales, 0)) * 100
        ELSE 0 
    END AS return_rate_percentage
FROM 
    RankedSales s
LEFT JOIN 
    SalesAndReturns r ON s.web_site_id = r.c_customer_id
WHERE 
    s.rank = 1
ORDER BY 
    net_sales DESC;
