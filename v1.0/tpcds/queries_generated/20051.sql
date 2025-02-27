
WITH RECURSIVE demographic_summary AS (
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
        RANK() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS purchase_rank
    FROM customer_demographics
),
top_demographics AS (
    SELECT 
        *
    FROM demographic_summary
    WHERE purchase_rank <= 10
),
address_count AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ca.ca_address_sk) AS address_count
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY c.c_customer_sk
),
item_sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ws_item_sk
),
ranked_sales AS (
    SELECT 
        *,
        NTILE(10) OVER (ORDER BY total_sales DESC) AS sales_decile
    FROM item_sales_summary
)
SELECT 
    t.c_customer_sk,
    t.cd_gender,
    t.cd_marital_status,
    t.cd_education_status,
    t.cd_purchase_estimate,
    t.cd_credit_rating,
    a.address_count,
    i.total_quantity,
    i.total_sales,
    COALESCE(i.total_sales / NULLIF(a.address_count, 0), 0) AS sales_per_address,
    CASE 
        WHEN t.cd_dep_employed_count > 0 THEN 'Employed'
        ELSE 'Unemployed'
    END AS employment_status,
    CASE 
        WHEN i.sales_decile = 1 THEN 'Top Seller'
        WHEN i.sales_decile = 10 THEN 'Bottom Seller'
        ELSE 'Average Seller'
    END AS seller_category
FROM top_demographics t
JOIN address_count a ON t.cd_demo_sk = a.c_customer_sk
LEFT JOIN ranked_sales i ON a.c_customer_sk = i.ws_item_sk
WHERE t.cd_gender IS NOT NULL
ORDER BY sales_per_address DESC, t.cd_purchase_estimate DESC
LIMIT 100 OFFSET 10
UNION ALL
SELECT 
    NULL AS c_customer_sk,
    'N/A' AS cd_gender,
    'N/A' AS cd_marital_status,
    'N/A' AS cd_education_status,
    0 AS cd_purchase_estimate,
    'N/A' AS cd_credit_rating,
    COUNT(DISTINCT ca.ca_address_sk) AS address_count,
    NULL AS total_quantity,
    NULL AS total_sales,
    0 AS sales_per_address,
    'N/A' AS employment_status,
    'No Sales' AS seller_category
FROM customer_address ca
WHERE NOT EXISTS (SELECT 1 FROM customer c WHERE c.c_current_addr_sk = ca.ca_address_sk)
GROUP BY ca.ca_country
ORDER BY address_count DESC;

