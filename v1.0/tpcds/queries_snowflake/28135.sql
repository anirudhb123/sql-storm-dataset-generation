
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COALESCE(cd.cd_gender, 'N/A') AS gender,
        COALESCE(cd.cd_marital_status, 'N/A') AS marital_status,
        COALESCE(cd.cd_education_status, 'N/A') AS education_status,
        COUNT(DISTINCT st.ss_ticket_number) AS total_purchases,
        SUM(st.ss_sales_price) AS total_spent,
        LISTAGG(DISTINCT ca.ca_city, ', ') WITHIN GROUP (ORDER BY ca.ca_city) AS cities,
        LISTAGG(DISTINCT ca.ca_state, ', ') WITHIN GROUP (ORDER BY ca.ca_state) AS states
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales st ON c.c_customer_sk = st.ss_customer_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
MaxSpend AS (
    SELECT 
        MAX(total_spent) AS max_spent
    FROM 
        CustomerStats
),
Benchmark AS (
    SELECT 
        cs.full_name,
        cs.gender,
        cs.marital_status,
        cs.education_status,
        cs.total_purchases,
        cs.total_spent,
        cs.cities,
        cs.states,
        CASE 
            WHEN cs.total_spent = ms.max_spent THEN 'Highest Spender'
            ELSE 'Regular Customer'
        END AS customer_category
    FROM 
        CustomerStats cs, MaxSpend ms
)
SELECT 
    customer_category,
    COUNT(*) AS number_of_customers,
    SUM(total_spent) AS total_revenue,
    AVG(total_purchases) AS avg_purchases
FROM 
    Benchmark
GROUP BY 
    customer_category
ORDER BY 
    total_revenue DESC;
