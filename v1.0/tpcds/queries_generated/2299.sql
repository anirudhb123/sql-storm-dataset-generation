
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
WebReturns AS (
    SELECT
        wr_returning_customer_sk,
        COUNT(*) AS total_web_returns,
        SUM(wr_return_amt) AS total_web_return_amount
    FROM
        web_returns
    GROUP BY
        wr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM
        customer_demographics
),
PurchasePatterns AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws_quantity) AS total_purchases,
        SUM(ws_sales_price) AS total_spent,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS rank_purchase
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    JOIN
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
OverallReturns AS (
    SELECT 
        p.*,
        COALESCE(wr.total_web_returns, 0) AS total_web_returns,
        COALESCE(wr.total_web_return_amount, 0) AS total_web_return_amount
    FROM 
        PurchasePatterns p
    LEFT JOIN 
        WebReturns wr ON p.c_customer_sk = wr.wr_returning_customer_sk
)
SELECT
    o.full_name,
    o.cd_gender,
    o.cd_marital_status,
    o.total_purchases,
    o.total_spent,
    o.total_returned_quantity,
    o.total_return_amount,
    o.total_web_returns,
    o.total_web_return_amount,
    CASE 
        WHEN o.total_spent > 1000 THEN 'High Value'
        WHEN o.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM 
    OverallReturns o
WHERE 
    o.rank_purchase <= 5
ORDER BY 
    o.total_spent DESC;
