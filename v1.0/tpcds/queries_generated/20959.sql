
WITH RECURSIVE income_summary AS (
    SELECT 
        cd.credit_rating,
        SUM(ss_net_paid) AS total_spent,
        COUNT(DISTINCT c_customer_id) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        cd.credit_rating IS NOT NULL
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        cd.credit_rating
    HAVING 
        SUM(ss_net_paid) > 1000
), 
average_income AS (
    SELECT 
        0.5 * (MAX(ib_upper_bound) + MIN(ib_lower_bound)) AS avg_income
    FROM 
        income_band
),
ranked_customers AS (
    SELECT 
        cs.credit_rating,
        cs.total_spent,
        cs.customer_count,
        RANK() OVER (PARTITION BY cs.credit_rating ORDER BY cs.total_spent DESC) AS rank
    FROM 
        income_summary cs
)
SELECT 
    cu.ca_city,
    rc.credit_rating,
    rc.total_spent,
    rc.customer_count,
    (CASE 
        WHEN rc.total_spent > ai.avg_income THEN 'Above Average'
        ELSE 'Below Average'
     END) AS spending_status
FROM 
    ranked_customers rc
JOIN 
    average_income ai ON 1=1
JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = rc.customer_count LIMIT 1)
WHERE 
    rc.rank <= 5
    AND cu.ca_state IS NOT NULL
ORDER BY 
    rc.total_spent DESC, cu.ca_city;
