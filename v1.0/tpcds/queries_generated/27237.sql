
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        COALESCE(LOWER(c.c_email_address), '') AS email_lower,
        COALESCE(UPPER(c.c_email_address), '') AS email_upper
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
),
date_info AS (
    SELECT 
        d.d_date_id,
        d.d_date,
        d.d_day_name,
        d.d_month_seq,
        d.d_year
    FROM date_dim AS d
    WHERE d.d_year >= 2020 AND d.d_year <= 2023
),
email_analysis AS (
    SELECT 
        ci.c_customer_id,
        ci.full_name,
        ci.cd_gender,
        SUBSTRING(ci.email_lower, 1, 3) AS email_prefix,
        CHAR_LENGTH(ci.email_lower) AS email_length,
        COUNT(wp.wp_web_page_sk) AS page_count
    FROM customer_info AS ci
    LEFT JOIN web_page AS wp ON wp.wp_customer_sk = ci.c_customer_id
    GROUP BY ci.c_customer_id, ci.full_name, ci.cd_gender, ci.email_lower
),
purchase_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        DATE(d.d_date) AS purchase_date,
        SUM(ws.ws_sales_price) AS total_spent
    FROM web_sales AS ws
    JOIN date_info AS d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_bill_customer_sk, DATE(d.d_date)
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.ca_city,
    ci.ca_state,
    ea.email_prefix,
    ea.email_length,
    COALESCE(pd.total_spent, 0) AS total_spent,
    COUNT(DISTINCT dp.purchase_date) AS purchase_days
FROM customer_info AS ci
JOIN email_analysis AS ea ON ci.c_customer_id = ea.c_customer_id
LEFT JOIN purchase_data AS pd ON ci.c_customer_id = pd.ws_bill_customer_sk
GROUP BY ci.full_name, ci.cd_gender, ci.ca_city, ci.ca_state, ea.email_prefix, ea.email_length
ORDER BY total_spent DESC, ci.full_name ASC;
