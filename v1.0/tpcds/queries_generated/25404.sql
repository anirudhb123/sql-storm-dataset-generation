
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city AS city,
        ca.ca_state AS state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
AggregateSales AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), 
StringProcessingBenchmark AS (
    SELECT 
        cd.full_name,
        cd.city,
        cd.state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        COALESCE(as.total_orders, 0) AS total_orders,
        COALESCE(as.total_sales, 0) AS total_sales,
        COALESCE(as.total_profit, 0) AS total_profit,
        LENGTH(cd.full_name) AS name_length,
        UPPER(cd.full_name) AS name_upper,
        LOWER(cd.full_name) AS name_lower,
        REPLACE(cd.full_name, ' ', '-') AS name_replaced,
        SUBSTRING(cd.full_name, 1, 5) AS name_substring
    FROM CustomerDetails cd
    LEFT JOIN AggregateSales as ON cd.c_customer_sk = as.ws_bill_customer_sk
)

SELECT 
    *,
    CONCAT('Customer ', full_name) AS customer_label,
    TRIM(name_upper) AS trimmed_name_upper,
    CONCAT_WS(', ', city, state) AS full_location,
    CASE 
        WHEN cd_gender = 'M' THEN 'Mr.'
        WHEN cd_gender = 'F' THEN 'Ms.'
        ELSE 'Customer'
    END AS salutation
FROM StringProcessingBenchmark
ORDER BY total_sales DESC
LIMIT 100;
