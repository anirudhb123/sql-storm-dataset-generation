
WITH shopping_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases,
        DENSE_RANK() OVER (ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer AS c
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT *
    FROM shopping_summary
    WHERE sales_rank <= 100
),
detailed_info AS (
    SELECT 
        tc.c_customer_id,
        tc.total_sales,
        tc.total_purchases,
        COALESCE(da.ca_city, 'Unknown') AS city,
        COALESCE(da.ca_state, 'Unknown') AS state,
        COALESCE(ad.cd_gender, 'Unknown') AS gender,
        ad.cd_marital_status,
        ad.cd_purchase_estimate
    FROM 
        top_customers AS tc
    LEFT JOIN 
        customer_address AS da ON tc.c_customer_id = da.ca_address_id
    LEFT JOIN 
        customer_demographics AS ad ON tc.c_customer_id = ad.cd_demo_sk
)
SELECT 
    d.c_customer_id,
    d.total_sales,
    d.total_purchases,
    d.city,
    d.state,
    d.gender,
    d.marital_status,
    d.cd_purchase_estimate,
    CASE 
        WHEN d.total_sales > 10000 THEN 'High Value'
        WHEN d.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    detailed_info AS d
WHERE 
    d.city IS NOT NULL AND d.state IS NOT NULL
ORDER BY 
    d.total_sales DESC
LIMIT 50;
