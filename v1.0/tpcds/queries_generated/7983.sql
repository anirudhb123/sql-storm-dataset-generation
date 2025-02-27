
WITH RankedReturns AS (
    SELECT
        wr.returning_customer_sk,
        wr.returned_date_sk,
        wr_item_sk,
        wr_return_quantity,
        wr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY wr.returned_date_sk ORDER BY wr_return_amt DESC) AS rn
    FROM web_returns wr
    WHERE wr.returned_date_sk BETWEEN 2400 AND 2500
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ReturnsSummary AS (
    SELECT
        rd.returning_customer_sk,
        SUM(rd.returned_quantity) AS total_returned_quantity,
        SUM(rd.return_amt) AS total_return_amt,
        COUNT(DISTINCT rd.returned_date_sk) AS return_days_count
    FROM RankedReturns rd
    WHERE rd.rn <= 3
    GROUP BY rd.returning_customer_sk
)
SELECT
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    rs.total_returned_quantity,
    rs.total_return_amt,
    rs.return_days_count
FROM CustomerDetails cd
JOIN ReturnsSummary rs ON cd.c_customer_sk = rs.returning_customer_sk
WHERE cd.cd_purchase_estimate > 5000
ORDER BY total_returned_amt DESC
LIMIT 50;
