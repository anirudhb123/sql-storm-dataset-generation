
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS first_purchase_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        wp.wp_url AS last_page_visited,
        wp.wp_creation_date_sk AS last_visit_date
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_page wp ON c.c_customer_sk = wp.wp_customer_sk
    JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON d.d_date_sk = c.c_first_sales_date_sk
    WHERE 
        d.d_year >= 2020
),
AggregatedGenderStats AS (
    SELECT 
        cd.cd_gender,
        COUNT(*) AS total_customers,
        COUNT(DISTINCT cd.cd_marital_status) AS unique_marital_statuses,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        CustomerDetails cd
    GROUP BY 
        cd.cd_gender
),
FilteredCustomers AS (
    SELECT 
        full_name,
        first_purchase_date,
        cd_gender,
        ca_city,
        ca_state,
        ca_country,
        last_page_visited,
        last_visit_date
    FROM 
        CustomerDetails
    WHERE 
        ca_city LIKE 'San%' AND ca_state = 'CA'
)
SELECT 
    fg.cd_gender,
    fg.total_customers,
    fg.unique_marital_statuses,
    fg.avg_purchase_estimate,
    fc.full_name,
    fc.first_purchase_date,
    fc.last_page_visited
FROM 
    AggregatedGenderStats fg
JOIN 
    FilteredCustomers fc ON fc.cd_gender = fg.cd_gender
ORDER BY 
    fg.total_customers DESC, fc.last_visit_date DESC
LIMIT 100;
