
WITH RankedSales AS (
    SELECT
        ws.bill_customer_sk,
        ws.sold_date_sk,
        ws.order_number,
        ws.net_profit,
        RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY ws.net_profit DESC) AS ProfitRank,
        DENSE_RANK() OVER (ORDER BY SUM(ws.net_profit) DESC) AS TotalProfitRank
    FROM
        web_sales ws
    JOIN
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1980 AND 1990
        AND ws.sold_date_sk >= (
            SELECT MIN(d_date_sk)
            FROM date_dim
            WHERE d_year = 2023
        )
    GROUP BY
        ws.bill_customer_sk, ws.sold_date_sk, ws.order_number, ws.net_profit
),
SalesSummary AS (
    SELECT
        R. bill_customer_sk,
        COUNT(DISTINCT R.order_number) AS total_orders,
        SUM(R.net_profit) AS total_profit,
        AVG(R.net_profit) AS average_profit,
        MAX(R.net_profit) AS max_profit
    FROM
        RankedSales R
    WHERE
        R.ProfitRank <= 5
    GROUP BY
        R.bill_customer_sk
),
TopCustomers AS (
    SELECT
        SS.bill_customer_sk,
        SS.total_orders,
        SS.total_profit,
        SS.average_profit,
        SS.max_profit,
        CD.cd_gender,
        CD.cd_income_band_sk
    FROM
        SalesSummary SS
    JOIN
        customer_demographics CD ON SS.bill_customer_sk = CD.cd_demo_sk
    WHERE
        SS.total_profit > (
            SELECT AVG(total_profit)
            FROM SalesSummary
        )
)
SELECT
    TC.bill_customer_sk,
    TC.total_orders,
    TC.total_profit,
    TC.average_profit,
    TC.max_profit,
    CASE 
        WHEN TC.cd_gender = 'M' THEN 'Male'
        WHEN TC.cd_gender = 'F' THEN 'Female'
        ELSE 'Unknown'
    END AS gender,
    IB.ib_lower_bound,
    IB.ib_upper_bound
FROM
    TopCustomers TC
LEFT JOIN
    household_demographics HD ON TC.bill_customer_sk = HD.hd_demo_sk
LEFT JOIN
    income_band IB ON HD.hd_income_band_sk = IB.ib_income_band_sk
ORDER BY
    TC.total_profit DESC
FETCH FIRST 100 ROWS ONLY;
