
WITH customer_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_paid) AS total_spent,
        STRING_AGG(DISTINCT p.p_promo_name, ', ') AS promotions_used
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        promotion AS p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE 
        ca.ca_city IS NOT NULL
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ca.ca_city, ca.ca_state
),
top_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS sales_rank
    FROM 
        customer_summary AS cs
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.total_spent,
    tc.sales_rank,
    cs.promotions_used
FROM 
    top_customers AS tc
JOIN 
    customer_summary AS cs ON tc.c_customer_id = cs.c_customer_id
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.sales_rank;
