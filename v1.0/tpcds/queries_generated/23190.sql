
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_birth_year,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer AS c
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_birth_year
),
HighProfitCustomers AS (
    SELECT 
        c_customer_id,
        total_profit,
        order_count,
        DENSE_RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM 
        CustomerSales
    WHERE 
        total_profit IS NOT NULL
),
AgeDemographics AS (
    SELECT 
        CASE 
            WHEN EXTRACT(YEAR FROM CURRENT_DATE) - c_birth_year < 30 THEN 'Under 30'
            WHEN EXTRACT(YEAR FROM CURRENT_DATE) - c_birth_year BETWEEN 30 AND 50 THEN '30 to 50'
            ELSE 'Over 50'
        END AS age_group,
        COUNT(*) AS customer_count
    FROM 
        (SELECT DISTINCT c_customer_id, c_birth_year FROM HighProfitCustomers) AS unique_customers
    GROUP BY 
        age_group
)
SELECT 
    ad.age_group,
    ad.customer_count,
    hpc.total_profit
FROM 
    AgeDemographics AS ad
JOIN 
    HighProfitCustomers AS hpc 
ON 
    ad.customer_count > 10
ORDER BY 
    hpc.total_profit DESC NULLS LAST
UNION ALL
SELECT 
    'Total' AS age_group,
    COUNT(*) AS customer_count,
    SUM(total_profit) AS total_profit
FROM 
    HighProfitCustomers
WHERE 
    total_profit IS NOT NULL
HAVING 
    COUNT(total_profit) > (SELECT COUNT(*) FROM customer) * 0.1
ORDER BY 
    total_profit DESC;
