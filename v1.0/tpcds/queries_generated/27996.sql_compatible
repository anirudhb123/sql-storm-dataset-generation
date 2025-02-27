
WITH address_summary AS (
    SELECT 
        ca.city AS city,
        ca.state AS state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate,
        STRING_AGG(DISTINCT cd.cd_gender) AS unique_genders
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_state = 'CA'
    GROUP BY 
        ca.city, ca.state
), 
top_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_customer_sk IN (
            SELECT 
                c_customer_sk 
            FROM 
                store_sales 
            GROUP BY 
                c_customer_sk 
            ORDER BY 
                SUM(ss_sales_price) DESC 
            LIMIT 10
        )
)
SELECT 
    a.city,
    a.state,
    a.customer_count,
    a.average_purchase_estimate,
    a.unique_genders,
    t.full_name,
    t.cd_gender,
    t.cd_marital_status,
    t.cd_education_status
FROM 
    address_summary a
JOIN 
    top_customers t ON a.customer_count > 0
ORDER BY 
    a.average_purchase_estimate DESC, a.customer_count DESC;
