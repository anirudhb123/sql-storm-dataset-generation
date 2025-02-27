
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_country,
        ca.ca_state,
        ca.ca_city,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases,
        SUM(ss.ss_ext_sales_price) AS total_spent,
        AVG(ss.ss_ext_sales_price) AS avg_purchase_value
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND ca.ca_state IN ('CA', 'NY', 'TX')
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate, ca.ca_country, ca.ca_state, ca.ca_city
),
demographic_summary AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers,
        SUM(total_purchases) AS total_purchases,
        SUM(total_spent) AS total_revenue,
        AVG(avg_purchase_value) AS avg_purchase_value
    FROM 
        customer_data
    JOIN 
        customer_address ca ON customer_data.ca_country = ca.ca_country
    GROUP BY 
        ca.ca_city, ca.ca_state
)
SELECT 
    ds.ca_city,
    ds.ca_state,
    ds.unique_customers,
    ds.total_purchases,
    ds.total_revenue,
    ds.avg_purchase_value 
FROM 
    demographic_summary ds
WHERE 
    ds.total_revenue > 10000
ORDER BY 
    ds.total_revenue DESC;
