
WITH CustomerReturns AS (
    SELECT 
        sr.store_sk,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        SUM(sr.return_amt_inc_tax) AS total_returned_amount,
        SUM(sr.return_quantity) AS total_returned_quantity
    FROM 
        store_returns sr
    WHERE 
        sr.returned_date_sk = (
            SELECT 
                MAX(d_date_sk) 
            FROM 
                date_dim 
            WHERE 
                d_date = CURRENT_DATE - INTERVAL '30 days'
        )
    GROUP BY 
        sr.store_sk
),
SalesData AS (
    SELECT 
        ws.store_sk,
        SUM(ws.net_paid) AS total_sales,
        SUM(ws.quantity) AS total_quantity_sold
    FROM 
        web_sales ws
    INNER JOIN 
        web_site w ON ws.web_site_sk = w.web_site_sk
    LEFT JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk 
    WHERE 
        dd.d_year = EXTRACT(YEAR FROM CURRENT_DATE) 
        AND dd.d_month = EXTRACT(MONTH FROM CURRENT_DATE)
    GROUP BY 
        ws.store_sk
),
AggregateData AS (
    SELECT 
        s.store_sk,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_quantity_sold, 0) AS total_quantity_sold,
        (COALESCE(sd.total_sales, 0) - COALESCE(cr.total_returned_amount, 0)) AS net_sales
    FROM 
        store s
    LEFT JOIN 
        CustomerReturns cr ON s.store_sk = cr.store_sk
    LEFT JOIN 
        SalesData sd ON s.store_sk = sd.store_sk
)
SELECT 
    a.store_sk,
    s.store_name,
    a.total_returns,
    a.total_sales,
    a.total_quantity_sold,
    a.net_sales,
    RANK() OVER (ORDER BY a.net_sales DESC) AS sales_rank
FROM 
    AggregateData a 
JOIN 
    store s ON a.store_sk = s.store_sk
WHERE 
    a.total_sales > 0 AND a.total_returns < 5
ORDER BY 
    a.net_sales DESC;
