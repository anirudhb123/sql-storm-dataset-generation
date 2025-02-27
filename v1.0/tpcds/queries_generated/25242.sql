
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ItemInfo AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        i.i_category
    FROM item i
    WHERE i.i_current_price > 20.00
),
Sales AS (
    SELECT 
        ss.ss_customer_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count
    FROM store_sales ss
    GROUP BY ss.ss_customer_sk
),
BenchmarkResults AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        si.i_item_desc,
        si.i_brand,
        si.i_category,
        (COALESCE(s.total_sales, 0) / NULLIF(s.transaction_count, 0)) AS avg_transaction_value
    FROM CustomerInfo ci
    JOIN Sales s ON ci.c_customer_sk = s.ss_customer_sk
    JOIN ItemInfo si ON si.i_item_sk IN (SELECT ss.ss_item_sk FROM store_sales ss WHERE ss.ss_customer_sk = ci.c_customer_sk)
    WHERE ci.cd_gender = 'M' AND ci.cd_marital_status = 'M'
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    i_item_desc,
    i_brand,
    i_category,
    ROUND(AVG(avg_transaction_value), 2) AS avg_transaction_value
FROM BenchmarkResults
GROUP BY 
    full_name, 
    ca_city, 
    ca_state, 
    cd_gender, 
    cd_marital_status, 
    cd_education_status, 
    cd_purchase_estimate, 
    i_item_desc, 
    i_brand, 
    i_category
ORDER BY avg_transaction_value DESC
LIMIT 100;
