
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_paid) AS total_spent,
        AVG(ss.ss_net_paid) AS avg_spent,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ss.ss_net_paid) DESC) AS gender_rank
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.total_spent,
        cs.gender_rank
    FROM 
        CustomerStats AS cs
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) * 1.5 FROM CustomerStats)
)

SELECT 
    cs.c_first_name || ' ' || cs.c_last_name AS customer_name,
    cs.total_sales,
    cs.total_spent,
    CASE 
        WHEN cs.gender_rank = 1 THEN 'Top Spender'
        ELSE 'Regular Spender'
    END AS spending_category
FROM 
    HighSpenders AS cs
LEFT JOIN 
    customer_address AS ca ON ca.ca_address_sk = (
        SELECT c.c_current_addr_sk 
        FROM customer AS c 
        WHERE c.c_customer_sk = cs.c_customer_sk
    )
WHERE 
    ca.ca_state IS NOT NULL 
    AND ca.ca_country = 'USA'
ORDER BY 
    total_spent DESC
LIMIT 10;
