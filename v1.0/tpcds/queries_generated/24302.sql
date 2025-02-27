
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_store_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
WebSalesWithReturns AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT wr_order_number) AS total_web_returns
    FROM 
        web_sales ws
    LEFT JOIN 
        web_returns wr ON ws.ws_order_number = wr.wr_order_number AND 
                         ws.ws_bill_customer_sk = wr.w_returning_customer_sk
    GROUP BY 
        ws.ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE
            WHEN cd.cd_credit_rating IS NULL THEN 'Unknown'
            ELSE cd.cd_credit_rating 
        END AS credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer_demographics cd
)
SELECT 
    c.c_customer_id,
    COALESCE(cr.total_store_returns, 0) AS total_returns,
    COALESCE(wb.total_web_sales, 0) AS web_total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.credit_rating
FROM 
    customer c
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.c_customer_sk
LEFT JOIN 
    WebSalesWithReturns wb ON c.c_customer_sk = wb.ws_bill_customer_sk
JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    (cd.cd_marital_status = 'M' OR cd.cd_purchase_estimate > 5000)
    AND (cr.total_store_returns > 0 OR wb.total_web_sales > 1000)
ORDER BY 
    total_returns DESC, web_total_sales DESC
LIMIT 50;
