
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(COALESCE(cr_return_quantity, 0)) AS total_returned_quantity,
        SUM(COALESCE(cr_return_amount, 0)) AS total_returned_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
SalesData AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_amount
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk 
    GROUP BY 
        ws.web_site_sk, ws.ws_sold_date_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(SUM(sd.total_sales_quantity), 0) AS total_sales_quantity,
    COALESCE(SUM(sd.total_sales_amount), 0) AS total_sales_amount,
    COALESCE(SUM(cr.total_returned_quantity), 0) AS total_returned_quantity,
    COALESCE(SUM(cr.total_returned_amount), 0) AS total_returned_amount,
    COUNT(DISTINCT cu.c_customer_id) AS unique_customers
FROM 
    CustomerDemographics cd
LEFT JOIN 
    CustomerReturns cr ON cd.cd_demo_sk = cr.cr_returning_customer_sk
LEFT JOIN 
    SalesData sd ON sd.web_site_sk IN (
        SELECT web_site_sk FROM web_site 
        WHERE web_country = 'USA'
    )
JOIN 
    customer cu ON cd.cd_demo_sk = cu.c_current_cdemo_sk
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
HAVING 
    COUNT(DISTINCT cu.c_customer_id) > 0
ORDER BY 
    cd.cd_gender, cd.cd_marital_status;
