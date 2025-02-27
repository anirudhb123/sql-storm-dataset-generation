
WITH CustomerOrders AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(ss.ss_ticket_number) AS order_count
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 20000101 AND 20221231
    GROUP BY 
        c.c_customer_id
),
IncomeStatistics AS (
    SELECT 
        d.ib_income_band_sk,
        AVG(cos.total_spent) AS avg_spent,
        COUNT(cos.c_customer_id) AS customer_count
    FROM 
        household_demographics d
    JOIN 
        CustomerOrders cos ON d.hd_demo_sk = cos.c_customer_sk
    GROUP BY 
        d.ib_income_band_sk
),
RankedIncome AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        is.avg_spent,
        is.customer_count,
        RANK() OVER (ORDER BY is.avg_spent DESC) AS rank
    FROM 
        IncomeStatistics is
    JOIN 
        income_band ib ON is.income_band_sk = ib.ib_income_band_sk
)
SELECT 
    ri.ib_income_band_sk,
    ri.ib_lower_bound,
    ri.ib_upper_bound,
    ri.avg_spent,
    ri.customer_count,
    ri.rank
FROM 
    RankedIncome ri
WHERE 
    ri.rank <= 10
ORDER BY 
    ri.avg_spent DESC;
