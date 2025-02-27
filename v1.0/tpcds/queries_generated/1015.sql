
WITH ranked_sales AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state,
        (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk) AS total_store_purchases
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        ci.ca_city,
        ci.ca_state,
        COALESCE(rs.total_sales, 0) AS web_sales,
        COALESCE(nil.total_store_purchases, 0) AS store_purchases
    FROM
        customer_info ci
    LEFT JOIN ranked_sales rs ON ci.c_customer_sk = rs.ws_bill_customer_sk
    LEFT JOIN (SELECT DISTINCT ws_bill_customer_sk, COUNT(*) AS total_store_purchases FROM store_sales GROUP BY ws_bill_customer_sk) nil ON ci.c_customer_sk = nil.ws_bill_customer_sk
)
SELECT
    s.c_customer_sk,
    s.c_first_name,
    s.c_last_name,
    s.cd_gender,
    s.cd_marital_status,
    s.cd_purchase_estimate,
    s.cd_credit_rating,
    s.ca_city,
    s.ca_state,
    s.web_sales,
    s.store_purchases,
    CASE
        WHEN s.web_sales > 1000 AND s.store_purchases > 10 THEN 'High Value Customer'
        WHEN s.web_sales > 500 THEN 'Mid Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value
FROM
    sales_summary s
WHERE
    s.cd_gender = 'F' 
    AND s.cd_marital_status = 'M'
    AND (s.cd_purchase_estimate IS NULL OR s.cd_purchase_estimate > 500)
ORDER BY
    s.web_sales DESC,
    s.store_purchases DESC
LIMIT 100;
