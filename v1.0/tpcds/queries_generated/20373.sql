
WITH RECURSIVE demographic_info AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS rnk
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate IS NOT NULL
),
store_sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS transaction_count
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk > (
            SELECT 
                MAX(d_date_sk) 
            FROM 
                date_dim 
            WHERE 
                d_date = CURRENT_DATE - INTERVAL '30 days'
        )
    GROUP BY 
        ss_store_sk
),
customer_results AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        da.ca_city,
        di.cd_gender,
        di.cd_marital_status,
        di.cd_purchase_estimate,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.transaction_count, 0) AS transaction_count
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS di ON c.c_current_cdemo_sk = di.cd_demo_sk
    LEFT JOIN 
        customer_address AS da ON c.c_current_addr_sk = da.ca_address_sk
    LEFT JOIN 
        store_sales_summary AS ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
        AND EXISTS (
            SELECT 1
            FROM demographic_info di_sub
            WHERE di_sub.cd_dep_count < 3
            AND di_sub.cd_demo_sk = di.cd_demo_sk
            AND di_sub.rnk < 5
        )
),
ranked_customers AS (
    SELECT 
        cr.*,
        RANK() OVER (PARTITION BY cr.ca_city ORDER BY cr.total_sales DESC) AS city_rnk
    FROM 
        customer_results cr
)
SELECT 
    rc.c_customer_id,
    rc.c_first_name,
    rc.c_last_name,
    rc.ca_city,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_purchase_estimate,
    rc.total_sales,
    rc.transaction_count
FROM 
    ranked_customers rc
WHERE 
    rc.city_rnk = 1
    AND (rc.cd_gender = 'M' OR rc.cd_marital_status = 'S')
ORDER BY 
    rc.total_sales DESC;
