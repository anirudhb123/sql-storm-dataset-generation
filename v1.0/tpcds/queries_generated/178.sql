
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
IncomeBand AS (
    SELECT 
        cd.cd_demo_sk, 
        ib.ib_lower_bound, 
        ib.ib_upper_bound
    FROM customer_demographics cd
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
AggregatedSales AS (
    SELECT 
        cs.c_customer_sk,
        MAX(cs.total_spent) AS highest_spent,
        AVG(cs.total_spent) AS average_spent,
        SUM(CASE WHEN cs.total_orders > 5 THEN 1 ELSE 0 END) AS frequent_buyers
    FROM CustomerSales cs
    GROUP BY cs.c_customer_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    MAX(as.highest_spent) AS highest_spent,
    AVG(as.average_spent) AS average_spent,
    SUM(as.frequent_buyers) AS total_frequent_buyers,
    COUNT(DISTINCT CASE WHEN cs.total_orders IS NOT NULL THEN cs.c_customer_sk END) AS non_null_orders
FROM CustomerSales cs
JOIN IncomeBand ib ON cs.c_customer_sk = ib.cd_demo_sk
JOIN AggregatedSales as ON cs.c_customer_sk = as.c_customer_sk
GROUP BY cs.c_first_name, cs.c_last_name, ib.ib_lower_bound, ib.ib_upper_bound
HAVING MAX(as.highest_spent) > 500
ORDER BY average_spent DESC
LIMIT 10;
