
WITH RECURSIVE customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag, 
           ca.ca_city, ca.ca_state, cd.cd_gender,
           -- Including nested CTE for sales info
           (SELECT COUNT(*) FROM store_sales ss 
            WHERE ss.ss_customer_sk = c.c_customer_sk) AS total_store_sales,
           (SELECT COUNT(*) FROM web_sales ws 
            WHERE ws.ws_bill_customer_sk = c.c_customer_sk) AS total_web_sales
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year < 1990
),
income_density AS (
    SELECT hd.hd_income_band_sk, COUNT(*) AS customer_count
    FROM household_demographics hd
    JOIN customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY hd.hd_income_band_sk
),
sales_summary AS (
    SELECT cs.cs_item_sk, SUM(cs.cs_ext_sales_price) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (SELECT d_date_sk 
                                  FROM date_dim 
                                  WHERE d_year = 2023)
    GROUP BY cs.cs_item_sk
),
joined_sales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.ca_city, c.ca_state,
           COALESCE(ss.total_store_sales, 0) AS total_store_sales,
           COALESCE(ws.total_web_sales, 0) AS total_web_sales,
           ISNULL(i.customer_count, 0) AS income_band
    FROM customer_info c
    LEFT JOIN sales_summary ss ON c.c_customer_sk = ss.cs_item_sk
    LEFT JOIN income_density i ON c.c_customer_sk = i.customer_count
),
final_output AS (
    SELECT j.*, 
           CASE 
               WHEN j.total_store_sales + j.total_web_sales > 1000 THEN 'High Value'
               WHEN j.total_store_sales > 500 THEN 'Medium Value'
               ELSE 'Low Value'
           END AS customer_value
    FROM joined_sales j
)
SELECT f.*, 
       CONCAT(f.c_first_name, ' ', f.c_last_name) AS full_name,
       f.ca_city || ', ' || f.ca_state AS full_address,
       ROW_NUMBER() OVER (ORDER BY f.total_store_sales + f.total_web_sales DESC) AS customer_rank,
       NTILE(5) OVER (ORDER BY f.total_store_sales + f.total_web_sales) AS sales_tier
FROM final_output f
WHERE f.ca_state IS NOT NULL
AND (f.total_store_sales > 0 OR f.total_web_sales > 0)
ORDER BY f.customer_rank;
