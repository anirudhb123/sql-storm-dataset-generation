
WITH CustomerReturns AS (
    SELECT
        wr_returning_customer_sk,
        COUNT(wr_order_number) AS total_web_returns,
        SUM(wr_return_amt_inc_tax) AS total_web_return_value,
        SUM(wr_return_quantity) AS total_returned_quantity
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY wr_returning_customer_sk
),
StoreReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_store_returns,
        SUM(sr_return_amt_inc_tax) AS total_store_return_value,
        SUM(sr_return_quantity) AS total_returned_quantity
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY sr_customer_sk
),
Demographics AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_income_band_sk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TotalReturns AS (
    SELECT
        COALESCE(cw.wr_returning_customer_sk, st.sr_customer_sk) AS customer_sk,
        COALESCE(cw.total_web_returns, 0) AS total_web_returns,
        COALESCE(cw.total_web_return_value, 0) AS total_web_return_value,
        COALESCE(st.total_store_returns, 0) AS total_store_returns,
        COALESCE(st.total_store_return_value, 0) AS total_store_return_value
    FROM CustomerReturns cw
    FULL OUTER JOIN StoreReturns st ON cw.wr_returning_customer_sk = st.sr_customer_sk
),
FinalOutput AS (
    SELECT
        d.c_customer_sk,
        d.cd_gender,
        d.cd_income_band_sk,
        tr.total_web_returns,
        tr.total_web_return_value,
        tr.total_store_returns,
        tr.total_store_return_value,
        ROW_NUMBER() OVER (PARTITION BY d.cd_income_band_sk ORDER BY tr.total_web_return_value DESC) AS rank_by_web_value
    FROM Demographics d
    LEFT JOIN TotalReturns tr ON d.c_customer_sk = tr.customer_sk
)
SELECT 
    f.c_customer_sk,
    f.cd_gender,
    f.cd_income_band_sk,
    f.total_web_returns,
    f.total_web_return_value,
    f.total_store_returns,
    f.total_store_return_value
FROM FinalOutput f
WHERE f.total_web_return_value > (
    SELECT AVG(total_web_return_value) 
    FROM FinalOutput 
    WHERE cd_income_band_sk = f.cd_income_band_sk
)
AND f.rank_by_web_value <= 10
ORDER BY f.cd_income_band_sk, f.total_web_return_value DESC;
