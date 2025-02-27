
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, ca_zip
    FROM customer_address
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT a.ca_address_sk, a.ca_city, a.ca_state, a.ca_country, a.ca_zip
    FROM customer_address a
    INNER JOIN address_hierarchy h ON a.ca_city = h.ca_city AND a.ca_state = h.ca_state
    WHERE a.ca_zip IS NOT NULL
),
sales_summary AS (
    SELECT
        ws_bill_cdemo_sk AS customer_demo_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY ws_bill_cdemo_sk
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        s.total_sales,
        COALESCE(hd.hd_dep_count, 0) AS dependent_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY s.total_sales DESC) AS sales_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN sales_summary s ON c.c_customer_sk = s.customer_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
gender_comparison AS (
    SELECT
        cd.cd_gender,
        AVG(total_sales) AS avg_sales
    FROM customer_details cd
    GROUP BY cd.cd_gender
),
sales_difference AS (
    SELECT 
        MAX(CASE WHEN cd.cd_gender = 'M' THEN cd.total_sales ELSE 0 END) - 
        MAX(CASE WHEN cd.cd_gender = 'F' THEN cd.total_sales ELSE 0 END) AS male_female_sales_diff
    FROM customer_details cd
)
SELECT 
    h.ca_city,
    h.ca_state,
    h.ca_country,
    COUNT(DISTINCT cd.c_customer_sk) AS customer_count,
    AVG(cd.total_sales) AS avg_sales,
    g.avg_sales AS avg_gender_sales,
    sd.male_female_sales_diff
FROM address_hierarchy h
JOIN customer_details cd ON h.ca_zip = cd.c_zip
JOIN gender_comparison g ON cd.cd_gender = g.cd_gender
CROSS JOIN sales_difference sd
GROUP BY h.ca_city, h.ca_state, h.ca_country, g.avg_sales, sd.male_female_sales_diff
HAVING COUNT(DISTINCT cd.c_customer_sk) > 5
ORDER BY avg_sales DESC, customer_count DESC;
