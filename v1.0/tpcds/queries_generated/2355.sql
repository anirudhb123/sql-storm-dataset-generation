
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returns,
        COUNT(DISTINCT cr_order_number) AS return_order_count,
        SUM(cr_return_amt_inc_tax) AS total_returned_amount
    FROM catalog_returns
    WHERE cr_returned_date_sk >= (SELECT MAX(d_date_sk) - 90 FROM date_dim)
    GROUP BY cr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
ActiveCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(c.ca_city, 'Unknown') AS city,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.hd_income_band_sk,
        cd.hd_buy_potential,
        r.total_returns,
        r.return_order_count,
        r.total_returned_amount
    FROM customer c
    LEFT JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns r ON c.c_customer_sk = r.cr_returning_customer_sk
    WHERE c.c_first_shipto_date_sk IS NOT NULL
),
AggregateSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 180 FROM date_dim)
    GROUP BY ws_bill_customer_sk
)
SELECT 
    ac.c_first_name,
    ac.c_last_name,
    ac.city,
    ac.cd_gender,
    ac.cd_marital_status,
    COALESCE(ab.total_sales, 0) AS total_sales,
    COALESCE(ab.order_count, 0) AS order_count,
    ac.total_returns,
    ac.return_order_count,
    ac.total_returned_amount
FROM ActiveCustomers ac
LEFT JOIN AggregateSales ab ON ac.c_customer_sk = ab.ws_bill_customer_sk
ORDER BY ac.total_returns DESC, total_sales DESC
LIMIT 100;
