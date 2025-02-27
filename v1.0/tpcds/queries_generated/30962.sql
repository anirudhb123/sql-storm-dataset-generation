
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        c.c_birth_year,
        c.c_preferred_cust_flag,
        SUM(ss.ss_net_profit) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_year, c.c_preferred_cust_flag
    HAVING 
        SUM(ss.ss_net_profit) IS NOT NULL
),
sales_ranking AS (
    SELECT 
        customer_name,
        total_sales,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_hierarchy
),
top_customers AS (
    SELECT 
        customer_name,
        total_sales
    FROM 
        sales_ranking
    WHERE 
        sales_rank <= 10
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    tc.customer_name,
    tc.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.ca_city,
    cd.ca_state,
    cd.ca_country
FROM 
    top_customers tc
LEFT JOIN 
    customer_demographics cd ON tc.customer_name = CONCAT(cd.cd_demo_sk, '') -- Join logic here may vary
ORDER BY 
    tc.total_sales DESC;
