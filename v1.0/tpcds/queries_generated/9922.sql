
WITH CustomerStats AS (
    SELECT
        cd.gender,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(CASE WHEN c.c_birth_year BETWEEN 1980 AND 1990 THEN 1 ELSE 0 END) AS millennials_count,
        SUM(CASE WHEN c.c_birth_year < 1980 THEN 1 ELSE 0 END) AS older_generations_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.gender
),
SalesStats AS (
    SELECT
        ws_bill_cdemo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_bill_cdemo_sk
),
BestCustomers AS (
    SELECT
        cs.gender,
        cs.total_customers,
        cs.millennials_count,
        cs.older_generations_count,
        cs.avg_purchase_estimate,
        ss.total_sales,
        ss.total_profit
    FROM CustomerStats cs
    JOIN SalesStats ss ON cs.total_customers = ss.ws_bill_cdemo_sk
)
SELECT 
    bc.gender,
    bc.total_customers,
    bc.millennials_count,
    bc.older_generations_count,
    bc.avg_purchase_estimate,
    bc.total_sales,
    bc.total_profit,
    RANK() OVER (ORDER BY bc.total_sales DESC) AS sales_rank
FROM BestCustomers bc
WHERE bc.total_sales > 10000
ORDER BY sales_rank
LIMIT 10;
