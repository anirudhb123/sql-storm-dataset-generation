
WITH CustomerCounts AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(sr.ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_return_quantity) AS total_return_quantity
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
),
DetailedReturns AS (
    SELECT
        c_first_name || ' ' || c_last_name AS customer_full_name,
        cd_gender,
        cd_marital_status,
        total_returns,
        total_return_amount,
        total_return_quantity
    FROM CustomerCounts
    WHERE total_returns > 0
),
RankedReturns AS (
    SELECT
        customer_full_name,
        cd_gender,
        cd_marital_status,
        total_returns,
        total_return_amount,
        total_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY total_return_amount DESC) AS rank
    FROM DetailedReturns
)
SELECT
    customer_full_name,
    cd_gender,
    cd_marital_status,
    total_returns,
    total_return_amount,
    total_return_quantity,
    CONCAT('Rank ', rank) AS return_rank
FROM RankedReturns
WHERE rank <= 10
ORDER BY cd_gender, return_rank;
