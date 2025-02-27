
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS total_return_count
    FROM store_returns
    GROUP BY sr_customer_sk
), 
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_sales_count
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = CURRENT_DATE - INTERVAL '1 year')
    GROUP BY ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender, 
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        CASE 
            WHEN ib.ib_income_band_sk IS NOT NULL THEN 'In Income Band'
            ELSE 'No Income Band'
        END AS income_band_status
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cd.c_customer_sk,
    COUNT(DISTINCT cdr.total_returned_quantity) AS unique_returned_counts,
    SUM(COALESCE(cdr.total_returned_quantity, 0)) AS total_returns,
    SUM(COALESCE(cdr.total_returned_amount, 0)) AS total_return_amounts,
    COALESCE(sd.total_sales, 0) AS total_online_sales,
    sd.total_sales_count AS total_sales_transactions,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.income_band_status
FROM CustomerDemographics cd
LEFT JOIN CustomerReturns cdr ON cd.c_customer_sk = cdr.sr_customer_sk
LEFT JOIN SalesData sd ON cd.c_customer_sk = sd.customer_sk
GROUP BY 
    cd.c_customer_sk, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.income_band_status
ORDER BY total_returns DESC, total_online_sales DESC
LIMIT 100;
