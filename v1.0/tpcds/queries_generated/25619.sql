
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        TRIM(UPPER(ca_city)) AS normalized_city,
        CAST(ca_zip AS CHAR(10)) AS zipcode_formatted
    FROM customer_address
),
gender_stats AS (
    SELECT 
        cd_gender,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd_gender
),
sales_data AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit
    FROM web_sales
    GROUP BY ws_bill_cdemo_sk
),
final_benchmark AS (
    SELECT 
        pa.full_address,
        pa.normalized_city,
        pa.zipcode_formatted,
        gs.cd_gender AS customer_gender,
        gs.customer_count,
        gs.avg_purchase_estimate,
        sd.total_sales,
        sd.avg_net_profit
    FROM processed_addresses pa
    LEFT JOIN gender_stats gs ON gs.customer_count > 50
    LEFT JOIN sales_data sd ON sd.ws_bill_cdemo_sk = gs.cd_demo_sk
    ORDER BY pa.normalized_city, gs.cd_gender
)
SELECT * FROM final_benchmark
WHERE customer_gender IS NOT NULL
AND total_sales > 10000
LIMIT 100;
