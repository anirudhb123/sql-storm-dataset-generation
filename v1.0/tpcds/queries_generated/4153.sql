
WITH CustomerReturns AS (
    SELECT
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_return_amt_inc_tax) AS total_returned_amount,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_sales_price) AS total_sales_amount,
        AVG(ws_net_paid_inc_tax) AS avg_net_paid,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT c.c_customer_sk,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FinalReport AS (
    SELECT
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
        COALESCE(sd.total_sales_quantity, 0) AS total_sales_quantity,
        COALESCE(sd.total_sales_amount, 0) AS total_sales_amount,
        COALESCE(sd.avg_net_paid, 0) AS avg_net_paid,
        CASE
            WHEN COALESCE(sd.total_orders, 0) > 0 THEN 'Active'
            ELSE 'Inactive'
        END AS customer_status
    FROM CustomerDemographics cd
    LEFT JOIN CustomerReturns cr ON cd.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT
    f.cd_gender,
    f.cd_marital_status,
    SUM(f.total_returned_quantity) AS total_returned_quantity,
    SUM(f.total_returned_amount) AS total_returned_amount,
    SUM(f.total_sales_quantity) AS total_sales_quantity,
    SUM(f.total_sales_amount) AS total_sales_amount,
    AVG(f.avg_net_paid) AS avg_net_paid,
    f.customer_status
FROM FinalReport f
GROUP BY f.cd_gender, f.cd_marital_status, f.customer_status
HAVING SUM(f.total_sales_quantity) > 0
ORDER BY f.total_sales_amount DESC, f.total_returned_amount ASC;
