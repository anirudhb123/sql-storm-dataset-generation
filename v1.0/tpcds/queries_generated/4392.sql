
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        COUNT(sr_ticket_number) AS total_returns, 
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM store_returns
    GROUP BY sr_customer_sk
), 
FrequentCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_purchase_estimate,
        r.ib_lower_bound,
        r.ib_upper_bound
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN income_band r ON hd.hd_income_band_sk = r.ib_income_band_sk
    WHERE cd.cd_purchase_estimate > 1000 AND cd.cd_marital_status = 'M'
),
ReturnSummary AS (
    SELECT 
        fc.c_customer_sk,
        fc.c_first_name,
        fc.c_last_name,
        COALESCE(cr.total_returns, 0) AS return_count,
        COALESCE(cr.total_return_value, 0) AS return_value
    FROM FrequentCustomers fc
    LEFT JOIN CustomerReturns cr ON fc.c_customer_sk = cr.sr_customer_sk
),
SalesAndReturns AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(COALESCE(sr.sr_return_amt_inc_tax, 0)) AS total_returns
    FROM web_sales ws
    LEFT JOIN store_returns sr ON ws.ws_item_sk = sr.sr_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2400 AND 2500
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
)

SELECT 
    rs.c_customer_sk,
    rs.c_first_name,
    rs.c_last_name,
    sa.ws_sold_date_sk,
    sa.ws_item_sk,
    sa.total_sales,
    sa.total_returns,
    CASE WHEN sa.total_sales > 0 THEN (sa.total_returns / sa.total_sales) * 100 ELSE NULL END AS return_percentage
FROM ReturnSummary rs
LEFT JOIN SalesAndReturns sa ON rs.c_customer_sk = sa.ws_bill_customer_sk
ORDER BY return_percentage DESC, rs.c_last_name ASC
LIMIT 100;
