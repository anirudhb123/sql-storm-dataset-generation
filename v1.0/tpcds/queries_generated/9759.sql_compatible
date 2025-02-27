
WITH CustomerReturns AS (
    SELECT 
        wr.returning_customer_sk,
        COUNT(wr.return_order_number) AS total_web_returns,
        SUM(wr.return_amt) AS total_return_amount,
        SUM(wr.return_tax) AS total_return_tax
    FROM web_returns wr
    GROUP BY wr.returning_customer_sk
),
StoreReturns AS (
    SELECT 
        sr.returning_customer_sk,
        COUNT(sr.return_ticket_number) AS total_store_returns,
        SUM(sr.return_amt) AS total_store_return_amount,
        SUM(sr.return_tax) AS total_store_return_tax
    FROM store_returns sr
    GROUP BY sr.returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
ReturnSummary AS (
    SELECT
        COALESCE(wr.returning_customer_sk, sr.returning_customer_sk) AS customer_sk,
        COALESCE(cus_demo.cd_gender, 'Unknown') AS gender,
        COALESCE(cus_demo.cd_marital_status, 'Unknown') AS marital_status,
        COALESCE(cust_r.total_web_returns, 0) AS total_web_returns,
        COALESCE(cust_r.total_return_amount, 0) AS total_web_return_amount,
        COALESCE(cust_r.total_return_tax, 0) AS total_web_return_tax,
        COALESCE(stor_r.total_store_returns, 0) AS total_store_returns,
        COALESCE(stor_r.total_store_return_amount, 0) AS total_store_return_amount,
        COALESCE(stor_r.total_store_return_tax, 0) AS total_store_return_tax
    FROM CustomerReturns cust_r
    FULL OUTER JOIN StoreReturns stor_r ON cust_r.returning_customer_sk = stor_r.returning_customer_sk
    FULL OUTER JOIN CustomerDemographics cus_demo ON COALESCE(cust_r.returning_customer_sk, stor_r.returning_customer_sk) = cus_demo.cd_demo_sk
)
SELECT 
    gender,
    marital_status,
    SUM(total_web_returns) AS sum_web_returns,
    SUM(total_web_return_amount) AS sum_web_return_amount,
    SUM(total_web_return_tax) AS sum_web_return_tax,
    SUM(total_store_returns) AS sum_store_returns,
    SUM(total_store_return_amount) AS sum_store_return_amount,
    SUM(total_store_return_tax) AS sum_store_return_tax
FROM ReturnSummary
GROUP BY gender, marital_status
ORDER BY gender, marital_status;
