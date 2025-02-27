
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        STRING_AGG(DISTINCT ca.ca_city, ', ') AS cities,
        COUNT(DISTINCT ca.ca_address_sk) AS unique_address_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS num_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
final_benchmark AS (
    SELECT 
        cd.c_customer_id,
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cities,
        cd.unique_address_count,
        ss.total_spent,
        ss.num_orders
    FROM customer_data cd
    LEFT JOIN sales_summary ss ON cd.c_customer_id = ss.ws_bill_customer_sk
    WHERE cd.cd_gender = 'M' 
      AND cd.unique_address_count > 1
      AND ss.total_spent > 1000
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cities,
    unique_address_count,
    total_spent,
    num_orders
FROM final_benchmark
ORDER BY total_spent DESC, num_orders DESC;
