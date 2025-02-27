
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_country,
        cd.cd_marital_status,
        cd.cd_gender,
        1 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
    
    UNION ALL
    
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ch.c_birth_country,
        ch.cd_marital_status,
        ch.cd_gender,
        level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_current_addr_sk
)
SELECT 
    ch.level,
    ch.c_birth_country,
    COUNT(c.c_customer_sk) AS customer_count,
    AVG(cd.cd_purchase_estimate) AS average_purchase_estimate,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    STRING_AGG(DISTINCT c.c_email_address) AS unique_emails,
    COUNT(DISTINCT ca.ca_address_id) AS unique_addresses
FROM customer_hierarchy ch
JOIN customer c ON ch.c_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE ch.c_birth_country IS NOT NULL
GROUP BY ch.level, ch.c_birth_country
ORDER BY ch.level DESC
LIMIT 100;

WITH sales_summary AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_sales_price) AS total_web_sales,
        SUM(cs.cs_sales_price) AS total_catalog_sales,
        SUM(ss.ss_sales_price) AS total_store_sales
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY d.d_year
),
sales_growth AS (
    SELECT 
        s1.d_year,
        s1.total_web_sales,
        s1.total_catalog_sales,
        s1.total_store_sales,
        LAG(s1.total_web_sales) OVER (ORDER BY s1.d_year) AS prev_web_sales,
        LAG(s1.total_catalog_sales) OVER (ORDER BY s1.d_year) AS prev_catalog_sales,
        LAG(s1.total_store_sales) OVER (ORDER BY s1.d_year) AS prev_store_sales
    FROM sales_summary s1
)
SELECT 
    d_year,
    total_web_sales,
    total_catalog_sales,
    total_store_sales,
    CASE 
        WHEN prev_web_sales IS NOT NULL THEN total_web_sales - prev_web_sales 
        ELSE NULL 
    END AS web_sales_growth,
    CASE 
        WHEN prev_catalog_sales IS NOT NULL THEN total_catalog_sales - prev_catalog_sales 
        ELSE NULL 
    END AS catalog_sales_growth,
    CASE 
        WHEN prev_store_sales IS NOT NULL THEN total_store_sales - prev_store_sales 
        ELSE NULL 
    END AS store_sales_growth
FROM sales_growth
WHERE total_web_sales > 50000
ORDER BY d_year;
