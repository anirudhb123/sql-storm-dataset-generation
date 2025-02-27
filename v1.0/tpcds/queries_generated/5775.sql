
WITH RankedReturns AS (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        COUNT(wr_order_number) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_returned_amount,
        DENSE_RANK() OVER (PARTITION BY wr_returning_customer_sk ORDER BY SUM(wr_return_quantity) DESC) AS return_rank
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
HighReturnCustomers AS (
    SELECT
        wr.returning_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM RankedReturns wr
    JOIN customer c ON wr.returning_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE wr.return_rank = 1
),
ReturnSummary AS (
    SELECT 
        hrc.returning_customer_sk,
        hrc.c_first_name,
        hrc.c_last_name,
        hrc.cd_gender,
        hrc.cd_marital_status,
        hrc.cd_education_status,
        COUNT(DISTINCT wr.wr_order_number) AS unique_orders,
        SUM(wr.wr_return_qty) AS total_quantity_returned,
        SUM(wr.wr_return_amt_inc_tax) AS total_amount_returned
    FROM HighReturnCustomers hrc
    JOIN web_returns wr ON hrc.returning_customer_sk = wr.wr_returning_customer_sk
    GROUP BY hrc.returning_customer_sk, hrc.c_first_name, hrc.c_last_name, hrc.cd_gender, hrc.cd_marital_status, hrc.cd_education_status
),
FinalOutput AS (
    SELECT 
        r.returning_customer_sk,
        r.c_first_name,
        r.c_last_name,
        r.cd_gender,
        r.cd_marital_status,
        r.cd_education_status,
        r.unique_orders,
        r.total_quantity_returned,
        r.total_amount_returned,
        CASE 
            WHEN r.total_quantity_returned > 100 THEN 'High Returner'
            WHEN r.total_quantity_returned BETWEEN 50 AND 100 THEN 'Medium Returner'
            ELSE 'Low Returner'
        END AS return_category
    FROM ReturnSummary r
)
SELECT 
    fo.*,
    d.d_year,
    d.d_month_seq,
    d.d_week_seq
FROM FinalOutput fo
JOIN date_dim d ON d.d_date_sk = CURRENT_DATE;
