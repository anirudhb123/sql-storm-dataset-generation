
WITH CustomerReturns AS (
    SELECT
        cr.returning_customer_sk,
        cr.retur
      ning_cdemo_sk,
        cr.return_quantity,
        cr.return_amount,
        cr.return_tax,
        cr.returned_date_sk,
        cr.returned_time_sk
    FROM
        catalog_returns cr
    WHERE
        cr.return_quantity > 0
), 
SalesData AS (
    SELECT 
        ws.web_site_sk,
        ws.w_sold_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk, ws.ws_sold_date_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT
    cd.gender,
    cd.marital_status,
    sd.total_sales,
    sd.total_discount,
    COUNT(cr.returning_customer_sk) AS total_returns,
    SUM(cr.return_quantity) AS total_return_quantity
FROM
    CustomerDemographics cd
JOIN
    SalesData sd ON cd.customer_count > 0
LEFT JOIN
    CustomerReturns cr ON cd.cd_demo_sk = cr.returning_cdemo_sk
GROUP BY
    cd.gender, cd.marital_status, sd.total_sales, sd.total_discount
ORDER BY
    total_sales DESC, total_returns DESC
LIMIT 100;
