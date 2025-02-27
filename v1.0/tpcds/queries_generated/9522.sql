
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
combined_data AS (
    SELECT 
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        ss.total_quantity,
        ss.total_sales,
        ss.order_count
    FROM customer_info ci
    LEFT JOIN sales_summary ss ON ci.c_customer_id = CAST(ss.ws_bill_customer_sk AS CHAR(16))
),
income_data AS (
    SELECT 
        ci.*,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM combined_data ci
    JOIN household_demographics hd ON ci.cd_purchase_estimate BETWEEN hd.hd_income_band_sk AND hd.hd_income_band_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    customer_id,
    c_first_name,
    c_last_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_quantity,
    total_sales,
    order_count,
    ca_city,
    ca_state,
    ca_country,
    ib_lower_bound,
    ib_upper_bound
FROM income_data
WHERE total_sales > 1000
ORDER BY total_sales DESC
LIMIT 50;
