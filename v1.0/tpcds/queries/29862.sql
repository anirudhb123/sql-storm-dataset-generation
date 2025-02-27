
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
promotion_info AS (
    SELECT 
        p.p_promo_name,
        p.p_start_date_sk,
        p.p_end_date_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_sales,
        SUM(ws.ws_ext_sales_price) AS total_revenue
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_name, p.p_start_date_sk, p.p_end_date_sk
),
sales_summary AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        ci.ca_zip,
        pi.p_promo_name,
        pi.total_sales,
        pi.total_revenue,
        DENSE_RANK() OVER (PARTITION BY ci.c_customer_sk ORDER BY pi.total_revenue DESC) AS revenue_rank
    FROM customer_info ci
    JOIN promotion_info pi ON ci.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_bill_customer_sk = ci.c_customer_sk LIMIT 1)
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    ca_country,
    ca_zip,
    p_promo_name,
    total_sales,
    total_revenue,
    revenue_rank
FROM sales_summary
WHERE revenue_rank <= 5
ORDER BY total_revenue DESC;
