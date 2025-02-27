
WITH CustomerCategory AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(sr.ticket_number) AS returns_count,
        SUM(sr.return_amt_inc_tax) AS total_return_amt,
        SUM(ws.net_paid) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON d.d_date_sk = sr.returned_date_sk OR d.d_date_sk = ws.sold_date_sk
    WHERE d.d_year >= 2020
    GROUP BY c.c_customer_sk, full_name, d.d_year, cd.cd_gender, cd.cd_marital_status
),
WeightedReturns AS (
    SELECT
        cc.c_customer_sk,
        cc.full_name,
        cc.d_year,
        cc.cd_gender,
        cc.cd_marital_status,
        cc.returns_count,
        cc.total_return_amt,
        cc.total_spent,
        CASE 
            WHEN cc.total_spent IS NULL OR cc.total_spent = 0 THEN 0 
            ELSE (cc.total_return_amt / cc.total_spent) * 100 
        END AS return_rate_percentage
    FROM CustomerCategory cc
)

SELECT 
    wr.full_name,
    wr.d_year,
    wr.cd_gender,
    wr.cd_marital_status,
    wr.returns_count,
    wr.total_return_amt,
    wr.total_spent,
    wr.return_rate_percentage
FROM WeightedReturns wr
WHERE wr.return_rate_percentage > 10
ORDER BY wr.return_rate_percentage DESC, wr.total_spent DESC
LIMIT 50;
