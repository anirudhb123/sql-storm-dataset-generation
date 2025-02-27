
WITH CustomerOrders AS (
    SELECT 
        C.c_customer_sk,
        C.c_first_name,
        C.c_last_name,
        COUNT(DISTINCT S.ss_ticket_number) AS total_orders,
        SUM(S.ss_net_paid) AS total_spent,
        SUM(CASE WHEN S.ss_sold_date_sk >= DATEADD(YEAR, -1, CURRENT_DATE) THEN S.ss_net_paid ELSE 0 END) AS total_spent_last_year
    FROM 
        customer C
    LEFT JOIN 
        store_sales S ON C.c_customer_sk = S.ss_customer_sk
    GROUP BY 
        C.c_customer_sk, C.c_first_name, C.c_last_name
),
IncomeSegmentation AS (
    SELECT 
        CD.cd_demo_sk,
        CASE 
            WHEN HD.hd_income_band_sk <= 1 THEN 'Low'
            WHEN HD.hd_income_band_sk <= 3 THEN 'Medium'
            ELSE 'High' 
        END AS income_band,
        COUNT(DISTINCT CO.c_customer_sk) AS customer_count
    FROM 
        customer_demographics CD
    JOIN 
        household_demographics HD ON CD.cd_demo_sk = HD.hd_demo_sk
    JOIN 
        CustomerOrders CO ON C.c_customer_sk = CO.c_customer_sk
    GROUP BY 
        CD.cd_demo_sk, HD.hd_income_band_sk
),
AggregatedData AS (
    SELECT 
        IS.income_band,
        SUM(CO.total_orders) AS total_orders,
        SUM(CO.total_spent) AS total_revenue,
        SUM(CO.total_spent_last_year) AS total_revenue_last_year
    FROM 
        IncomeSegmentation IS
    JOIN 
        CustomerOrders CO ON IS.customer_count > 0
    GROUP BY 
        IS.income_band
)
SELECT 
    income_band,
    total_orders,
    total_revenue,
    total_revenue_last_year,
    ROUND((total_revenue - total_revenue_last_year) / NULLIF(total_revenue_last_year, 0) * 100, 2) AS growth_percentage
FROM 
    AggregatedData
ORDER BY 
    income_band;
