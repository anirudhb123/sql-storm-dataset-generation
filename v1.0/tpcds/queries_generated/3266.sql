
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY ws_bill_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
high_value_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        ss.total_sales,
        ss.order_count
    FROM customer_info ci
    JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
    WHERE ss.sales_rank <= 10
)
SELECT 
    hv.c_first_name || ' ' || hv.c_last_name AS customer_name,
    hv.cd_gender,
    hv.cd_marital_status,
    hv.cd_purchase_estimate,
    hv.cd_credit_rating,
    COALESCE(hv.total_sales, 0) AS total_sales,
    hv.order_count,
    (SELECT COUNT(*) 
     FROM store s 
     WHERE s.s_state = 'CA') AS ca_store_count
FROM high_value_customers hv
LEFT JOIN store s ON hv.total_sales > 1000 AND s.s_state = 'CA'
ORDER BY hv.total_sales DESC;
