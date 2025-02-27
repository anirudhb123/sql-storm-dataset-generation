
WITH address_summary AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT ca_city) AS unique_cities,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
customer_segment AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase
    FROM 
        customer_demographics AS cd
    JOIN 
        customer AS c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_gender
),
sales_analysis AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(ss_ext_sales_price) AS total_store_sales
    FROM 
        date_dim AS d
    LEFT JOIN 
        web_sales AS ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        store_sales AS ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        d.d_year
),
combined_results AS (
    SELECT 
        as.ca_state,
        as.total_addresses,
        as.unique_cities,
        as.avg_street_name_length,
        cs.cd_gender,
        cs.total_customers,
        cs.avg_purchase,
        sa.d_year,
        sa.total_web_sales,
        sa.total_store_sales
    FROM 
        address_summary AS as
    CROSS JOIN 
        customer_segment AS cs
    CROSS JOIN 
        sales_analysis AS sa
)
SELECT 
    ca_state,
    total_addresses,
    unique_cities,
    avg_street_name_length,
    cd_gender,
    total_customers,
    avg_purchase,
    d_year,
    total_web_sales,
    total_store_sales,
    (total_web_sales + total_store_sales) AS total_sales_combined
FROM 
    combined_results
WHERE 
    total_addresses > 1000 
    AND total_customers > 100 
ORDER BY 
    total_sales_combined DESC
LIMIT 100;
