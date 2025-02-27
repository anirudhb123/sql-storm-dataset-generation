
WITH RECURSIVE address_details AS (
    SELECT 
        ca_address_sk,
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS city_rank
    FROM customer_address
    WHERE ca_country IS NOT NULL
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        SUM(ws.ws_sales_price) AS total_sales
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
sales_summary AS (
    SELECT 
        ci.c_customer_id,
        SUM(CASE WHEN ci.total_sales IS NULL THEN 0 ELSE ci.total_sales END) AS total_sales_value,
        COUNT(CASE WHEN ci.total_sales > 1000 THEN 1 END) AS high_spenders
    FROM customer_info ci
    GROUP BY ci.c_customer_id
)
SELECT 
    ad.full_address,
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    ss.total_sales_value,
    ss.high_spenders,
    (SELECT COUNT(*) FROM customer c WHERE c.c_birth_month = 12 AND c.c_birth_year IS NOT NULL) AS december_birthdays,
    (SELECT SUM(sr_return_quantity) FROM store_returns sr WHERE sr.returned_date_sk = CI.total_sales_value) * 0.1 AS estimated_loss
FROM address_details ad
JOIN customer_info ci ON ci.total_sales IS NOT NULL
JOIN sales_summary ss ON ss.c_customer_id = ci.c_customer_id
WHERE 
    ((ci.cd_gender = 'F' AND ss.total_sales_value > (SELECT AVG(total_sales_value) FROM sales_summary)) OR 
    (ci.cd_gender = 'M' AND ss.high_spenders > 0)) 
    AND ad.city_rank <= 10
ORDER BY ad.ca_city, ss.total_sales_value DESC
FETCH FIRST 100 ROWS ONLY;
