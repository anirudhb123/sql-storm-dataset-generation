
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        (SELECT COUNT(*) 
         FROM store_sales ss 
         WHERE ss.ss_customer_sk = c.c_customer_sk 
           AND ss_ss_sales_price > 100) AS high_value_purchases,
        CASE 
            WHEN cd.cd_credit_rating IS NULL THEN 'Unknown'
            ELSE cd.cd_credit_rating
        END AS effective_credit_rating,
        COALESCE(NULLIF(c.c_email_address, ''), 'No Email Provided') AS safe_email
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    WHERE c.c_birth_year < 1980
), recent_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_web_sales,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_date BETWEEN '2022-01-01' AND '2022-12-31')
    GROUP BY ws_bill_customer_sk
), combined_results AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cr.high_value_purchases,
        cr.effective_credit_rating,
        cr.safe_email,
        rs.total_web_sales,
        rs.sales_rank
    FROM customer_data cr
    LEFT JOIN recent_sales rs ON cr.c_customer_id = rs.ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    COALESCE(c.high_value_purchases, 0) AS high_value_purchases,
    c.effective_credit_rating,
    c.safe_email,
    c.total_web_sales,
    c.sales_rank
FROM combined_results c
ORDER BY c.total_web_sales DESC
LIMIT 100
UNION ALL
SELECT 
    'TOTAL' AS c_customer_id,
    'Total Sales' AS c_first_name,
    NULL AS c_last_name,
    NULL AS cd_gender,
    NULL AS cd_marital_status,
    NULL AS high_value_purchases,
    NULL AS effective_credit_rating,
    NULL AS safe_email,
    SUM(COALESCE(total_web_sales, 0)) AS total_web_sales,
    NULL AS sales_rank
FROM combined_results
HAVING SUM(COALESCE(total_web_sales, 0)) > 10000
ORDER BY total_web_sales DESC;
