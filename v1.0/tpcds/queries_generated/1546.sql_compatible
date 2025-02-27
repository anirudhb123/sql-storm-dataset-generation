
WITH CustomerReturns AS (
    SELECT 
        sr.store_sk,
        sr.returned_date_sk,
        sr.return_quantity,
        sr.return_amt,
        sr.reason_sk,
        c.c_gender,
        c.c_birth_country
    FROM 
        store_returns sr
    JOIN 
        customer c ON sr.customer_sk = c.c_customer_sk
    WHERE 
        sr.return_quantity > 0
),
SalesSummary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.net_paid) AS total_sales,
        AVG(ws.net_profit) AS average_profit,
        COUNT(DISTINCT ws.ship_customer_sk) AS customer_count
    FROM 
        web_sales ws
    INNER JOIN 
        web_site w ON ws.web_site_sk = w.web_site_sk
    GROUP BY 
        ws.web_site_sk
),
ExcessReturns AS (
    SELECT 
        cr.store_sk,
        cr.reason_sk,
        COUNT(*) AS total_returns,
        SUM(cr.return_amt) AS total_return_amount
    FROM 
        CustomerReturns cr
    GROUP BY 
        cr.store_sk, cr.reason_sk
    HAVING 
        COUNT(*) > 10
)
SELECT 
    ss.web_site_sk,
    ss.total_sales,
    ss.average_profit,
    er.total_returns,
    er.total_return_amount,
    COALESCE(er.reason_sk, 'N/A') AS reason
FROM 
    SalesSummary ss
LEFT JOIN 
    ExcessReturns er ON ss.web_site_sk = er.store_sk
WHERE 
    ss.total_sales > 10000 
ORDER BY 
    ss.total_sales DESC;
