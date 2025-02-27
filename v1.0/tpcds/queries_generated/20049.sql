
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        SUM(ws_ext_sales_price) AS total_sales, 
        DENSE_RANK() OVER (PARTITION BY ws_web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk, 
        c.c_email_address, 
        cd.cd_gender,
        coalesce(cd.cd_marital_status, 'Unknown') AS marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'UNKNOWN'
            ELSE CAST(cd.cd_purchase_estimate AS VARCHAR)
        END AS purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TotalReturns AS (
    SELECT 
        sr.return_quantity,
        sr.return_amt,
        cr.returning_customer_sk,
        CASE 
            WHEN sr.return_quantity IS NULL THEN 0
            WHEN sr.return_quantity < 0 THEN -1 * sr.return_quantity
            ELSE sr.return_quantity
        END AS adjusted_return_quantity
    FROM 
        store_returns sr
    FULL OUTER JOIN 
        catalog_returns cr ON sr.sr_item_sk = cr.cr_item_sk AND sr.sr_ticket_number = cr.cr_order_number
    WHERE 
        sr.return_amt IS NOT NULL OR cr.return_amount IS NOT NULL
)
SELECT 
    wd.d_date AS Sale_Date,
    SUM(ts.total_sales) AS Total_Web_Sales,
    SUM(tr.adjusted_return_quantity) AS Total_Adjusted_Returns,
    COUNT(DISTINCT cd.c_customer_sk) AS Unique_Customers,
    AVG(wp.wp_access_date_sk) AS Avg_Page_Access_Date
FROM 
    date_dim wd
JOIN 
    RankedSales ts ON wd.d_date_sk = ts.web_site_sk
LEFT JOIN 
    TotalReturns tr ON wd.d_date_sk = tr.returning_customer_sk
RIGHT JOIN 
    CustomerDetails cd ON tr.returning_customer_sk = cd.c_customer_sk
WHERE 
    wd.d_year = 2023 
    AND (cd.marital_status = 'M' OR cd.marital_status = 'S') 
GROUP BY 
    wd.d_date, wd.d_month_seq
HAVING 
    SUM(ts.total_sales) IS NOT NULL
    AND COUNT(cd.c_customer_sk) > 10
ORDER BY 
    Sale_Date DESC;
