
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(sr_return_qty, 0) + COALESCE(cr_return_quantity, 0) + COALESCE(wr_return_quantity, 0)) AS total_returns
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY c.c_customer_id
),
DemographicDetails AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        chd.hd_income_band_sk,
        chd.hd_buy_potential
    FROM customer_demographics cd
    JOIN household_demographics chd ON cd.cd_demo_sk = chd.hd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
Summary AS (
    SELECT 
        cr.c_customer_id,
        dd.cd_gender,
        dd.cd_marital_status,
        dd.cd_purchase_estimate,
        dd.cd_credit_rating,
        dd.hd_income_band_sk,
        dd.hd_buy_potential,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(cr.total_returns, 0) AS total_returns,
        ss.order_count
    FROM CustomerReturns cr
    JOIN DemographicDetails dd ON cr.c_customer_id = dd.cd_gender
    LEFT JOIN SalesSummary ss ON cr.c_customer_id = ss.ws_bill_customer_sk
)
SELECT 
    summary.*,
    (total_sales - total_returns) AS net_spending
FROM Summary summary
ORDER BY net_spending DESC;
