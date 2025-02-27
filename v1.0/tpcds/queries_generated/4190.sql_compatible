
WITH CustomerPerformance AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_income_band_sk
),
RankedPerformance AS (
    SELECT 
        cp.c_customer_sk,
        cp.c_first_name,
        cp.c_last_name,
        cp.cd_gender,
        cp.cd_income_band_sk,
        cp.total_spent,
        cp.order_count,
        RANK() OVER (PARTITION BY cp.cd_income_band_sk ORDER BY cp.total_spent DESC) AS spending_rank
    FROM CustomerPerformance cp
),
TopCustomers AS (
    SELECT 
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        r.cd_gender,
        r.cd_income_band_sk,
        r.total_spent,
        r.order_count
    FROM RankedPerformance r
    WHERE r.spending_rank <= 5
),
DateWithReturns AS (
    SELECT 
        dd.d_date,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns,
        COALESCE(SUM(cr.cr_return_quantity), 0) AS catalog_returns
    FROM date_dim dd
    LEFT JOIN store_returns sr ON dd.d_date_sk = sr.sr_returned_date_sk
    LEFT JOIN catalog_returns cr ON dd.d_date_sk = cr.cr_returned_date_sk
    GROUP BY dd.d_date
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_income_band_sk,
    tc.total_spent,
    tc.order_count,
    dw.total_returns,
    dw.catalog_returns,
    CASE 
        WHEN tc.cd_income_band_sk IS NOT NULL THEN 'Not Null'
        ELSE 'Null Income Band'
    END AS income_band_status
FROM TopCustomers tc
JOIN DateWithReturns dw ON dw.total_returns > 0
ORDER BY tc.total_spent DESC, tc.c_last_name;
