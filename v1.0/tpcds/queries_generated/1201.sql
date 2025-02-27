
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
IncomeRanges AS (
    SELECT 
        ib.ib_income_band_sk, 
        ib.ib_lower_bound, 
        ib.ib_upper_bound
    FROM income_band ib
    WHERE ib.ib_lower_bound IS NOT NULL AND ib.ib_upper_bound IS NOT NULL
),
SalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
ReturnsSummary AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt) AS total_returns
    FROM web_returns wr
    GROUP BY wr.wr_returning_customer_sk
),
FinalReport AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        ir.ib_lower_bound,
        ir.ib_upper_bound,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(ss.total_sales, 0) - COALESCE(rs.total_returns, 0) AS net_sales
    FROM RankedCustomers rc
    LEFT JOIN IncomeRanges ir ON rc.cd_income_band_sk = ir.ib_income_band_sk
    LEFT JOIN SalesSummary ss ON rc.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN ReturnsSummary rs ON rc.c_customer_sk = rs.wr_returning_customer_sk
    WHERE rc.rank <= 10
)
SELECT 
    f.c_first_name,
    f.c_last_name,
    f.ib_lower_bound,
    f.ib_upper_bound,
    f.total_sales,
    f.total_returns,
    f.net_sales
FROM FinalReport f
ORDER BY f.net_sales DESC;
