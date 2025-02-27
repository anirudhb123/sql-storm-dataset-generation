
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_addr_sk,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws.ws_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_customer_sk
),
ReturnsSummary AS (
    SELECT 
        wr.wr_returning_customer_sk,
        COUNT(wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    GROUP BY wr.wr_returning_customer_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_marital_status,
    ss.total_sales,
    ss.order_count,
    rs.total_returns,
    rs.total_return_amt,
    CASE WHEN ss.total_sales IS NULL THEN 'No Sales' ELSE 'Sales Present' END AS sales_status,
    CASE WHEN rs.total_returns IS NULL THEN 'No Returns' ELSE 'Returns Present' END AS returns_status
FROM CustomerInfo ci
LEFT JOIN SalesSummary ss ON ci.c_customer_sk = ss.ws_customer_sk
LEFT JOIN ReturnsSummary rs ON ci.c_customer_sk = rs.wr_returning_customer_sk
WHERE (ci.cd_purchase_estimate > 1000 OR ci.cd_credit_rating = 'Good')
ORDER BY ci.c_last_name, ci.c_first_name;
