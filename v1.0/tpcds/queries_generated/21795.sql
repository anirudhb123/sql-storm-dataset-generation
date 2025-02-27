
WITH customer_info AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           ca_state,
           cd_demo_sk,
           cd_gender,
           cd_marital_status,
           cd_purchase_estimate
    FROM customer 
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    JOIN customer_address ON c_current_addr_sk = ca_address_sk
    WHERE ca_state IS NOT NULL
),
sales_data AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_net_paid_inc_tax) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS order_count,
           RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
gender_sales AS (
    SELECT c.gender,
           s.total_sales,
           s.order_count,
           (CASE 
                WHEN s.total_sales IS NULL THEN 0
                ELSE s.total_sales / NULLIF(s.order_count, 0)
            END) AS average_sales_per_order
    FROM (
        SELECT cd_gender AS gender, 
               SUM(total_sales) AS total_sales,
               SUM(order_count) AS order_count
        FROM customer_info ci
        JOIN sales_data s ON ci.c_customer_sk = s.ws_bill_customer_sk
        GROUP BY cd_gender
    ) AS c
    JOIN sales_data s ON c.gender = s.gender
),
final_output AS (
    SELECT *,
           (CASE 
                WHEN total_sales > 1000 THEN 'High'
                WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium'
                ELSE 'Low'
            END) AS sales_category,
           CASE 
                WHEN total_sales IS NULL THEN 'Unknown'
                ELSE CONCAT('Total: ', CAST(total_sales AS VARCHAR), 
                            ' | Avg: ', CAST(average_sales_per_order AS VARCHAR))
           END AS summary
    FROM gender_sales
)
SELECT ca_state,
       COUNT(*) AS number_of_customers,
       SUM(total_sales) AS total_sales,
       MAX(sales_rank) AS highest_sales_rank,
       AVG(average_sales_per_order) AS avg_sales_per_order
FROM final_output
JOIN customer_info ci ON final_output.gender = ci.cd_gender
GROUP BY ca_state
HAVING COUNT(*) > 5
ORDER BY number_of_customers DESC, total_sales DESC
LIMIT 10;
