
WITH SalesData AS (
    SELECT
        ss.sold_date_sk,
        SUM(ss.net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.customer_sk) AS unique_customers,
        SUM(ss.quantity) AS total_quantity
    FROM
        store_sales ss
    WHERE
        ss.sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ss.sold_date_sk
),
CustomerSegment AS (
    SELECT
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(c.c_birth_year) AS total_birth_year
    FROM
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        c.c_birth_year IS NOT NULL
    GROUP BY
        cd.cd_gender
),
ReturnsData AS (
    SELECT
        sr.returned_date_sk,
        SUM(sr.return_amt) AS total_return_amt,
        COUNT(sr.returning_customer_sk) AS total_returns
    FROM
        store_returns sr
    WHERE
        sr.returned_date_sk IN (SELECT DISTINCT ss.sold_date_sk FROM store_sales ss)
    GROUP BY
        sr.returned_date_sk
)
SELECT
    sd.sold_date_sk,
    sd.total_net_profit,
    sd.unique_customers,
    sd.total_quantity,
    cs.customer_count AS total_customers_by_gender,
    rd.total_return_amt,
    rd.total_returns
FROM
    SalesData sd
LEFT JOIN CustomerSegment cs ON cs.customer_count > 100
LEFT JOIN ReturnsData rd ON rd.returned_date_sk = sd.sold_date_sk
WHERE
    sd.total_net_profit > (SELECT AVG(total_net_profit) FROM SalesData)
ORDER BY
    sd.sold_date_sk DESC;
