
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_return_amt) AS total_return_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
), 
CustomerSales AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_quantity) AS total_sold_quantity,
        SUM(ws_sales_price) AS total_sales_amount
    FROM 
        web_sales
    GROUP BY 
        ws_ship_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
RankedSales AS (
    SELECT 
        cs.bill_customer_sk,
        RANK() OVER (PARTITION BY cs.bill_customer_sk ORDER BY cs.net_profit DESC) AS sales_rank,
        cs.net_profit
    FROM 
        catalog_sales cs
)
SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(COALESCE(cr.total_returned_quantity, 0)) AS total_returned_quantity,
    SUM(COALESCE(cs.total_sold_quantity, 0)) AS total_sold_quantity,
    SUM(COALESCE(cr.total_return_amount, 0)) AS total_return_amount,
    SUM(COALESCE(cs.total_sales_amount, 0)) AS total_sales_amount,
    COUNT(DISTINCT rs.bill_customer_sk) AS distinct_categories_sold
FROM 
    CustomerDemographics cd
LEFT JOIN 
    CustomerReturns cr ON cd.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN 
    CustomerSales cs ON cd.c_customer_sk = cs.ws_ship_customer_sk
LEFT JOIN 
    RankedSales rs ON cd.c_customer_sk = rs.bill_customer_sk
WHERE 
    (cd.cd_marital_status = 'M' AND cd.cd_gender = 'F' OR cd.cd_purchase_estimate > 1000)
GROUP BY 
    cd.c_customer_sk, cd.cd_gender, cd.cd_marital_status
HAVING 
    SUM(COALESCE(cs.total_sold_quantity, 0)) > 50
ORDER BY 
    total_sales_amount DESC
FETCH FIRST 10 ROWS ONLY;
