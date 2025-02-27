
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_customer_sk
),
SalesData AS (
    SELECT
        ws_ship_customer_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_net_paid_inc_tax) AS avg_net_paid
    FROM web_sales
    GROUP BY ws_ship_customer_sk
),
CustomerDemographics AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        CASE
            WHEN cd.cd_credit_rating IS NULL THEN 'Unknown'
            ELSE cd.cd_credit_rating
        END AS credit_rating,
        RANK() OVER (PARTITION BY cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.credit_rating,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_profit, 0) AS total_profit,
    cd.purchase_rank
FROM CustomerDemographics cd
LEFT JOIN CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
LEFT JOIN SalesData sd ON cd.c_customer_sk = sd.ws_ship_customer_sk
WHERE (cd.cd_gender = 'F' AND cd.cd_marital_status = 'M') OR 
      (cd.purchase_rank <= 5 AND cd.cd_income_band_sk BETWEEN 1 AND 3)
ORDER BY total_returns DESC, total_sales DESC;
