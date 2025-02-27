
WITH RECURSIVE DateRange AS (
    SELECT d_date_sk, d_date, 1 AS year_count
    FROM date_dim
    WHERE d_date >= DATE '2021-01-01' AND d_date <= DATE '2023-12-31'
    UNION ALL
    SELECT d_date_sk, d_date, year_count + 1
    FROM date_dim d
    INNER JOIN DateRange dr ON d.d_date_sk = dr.d_date_sk + 1
    WHERE dr.year_count < 3
),
CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr_ticket_number) as store_returns_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt_inc_tax) AS total_web_return_amt,
        COUNT(*) AS web_returns_count
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
TotalReturns AS (
    SELECT
        cr.c_customer_sk,
        COALESCE(cr.store_returns_count, 0) + COALESCE(wr.web_returns_count, 0) AS total_returns,
        COALESCE(cr.total_return_amt, 0) + COALESCE(wr.total_web_return_amt, 0) AS total_return_value
    FROM CustomerReturns cr
    FULL OUTER JOIN WebReturns wr ON cr.c_customer_sk = wr.wr_returning_customer_sk
)
SELECT 
    cd.cd_gender,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    AVG(tr.total_returns) AS average_returns,
    SUM(tr.total_return_value) AS total_return_value
FROM TotalReturns tr
JOIN customer c ON tr.c_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN DateRange dr ON dr.d_date_sk IN (c.c_first_sales_date_sk, c.c_first_shipto_date_sk)
WHERE cd.cd_marital_status = 'M'
GROUP BY cd.cd_gender
ORDER BY cd.cd_gender;
