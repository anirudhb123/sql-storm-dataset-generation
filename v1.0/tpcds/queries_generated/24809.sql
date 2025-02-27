
WITH customer_info AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_birth_month,
           cd.cd_gender,
           MAX(CASE WHEN cd.cd_marital_status = 'M' THEN cd.cd_purchase_estimate ELSE 0 END) AS marital_purchase_estimate,
           COUNT(DISTINCT cr.returning_customer_sk) FILTER (WHERE cr.returning_customer_sk IS NOT NULL) AS num_returns
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN (
        SELECT cr_returning_customer_sk
        FROM catalog_returns
        WHERE cr_return_quantity > 0
    ) AS cr ON c.c_customer_sk = cr.returning_customer_sk
    WHERE c.c_birth_month IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_month, cd.cd_gender
),
sales_info AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_sales_price) AS total_sales,
           COUNT(ws_order_number) AS total_orders,
           AVG(ws_net_paid) OVER (PARTITION BY ws_bill_customer_sk) AS average_net_paid
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
combined_info AS (
    SELECT ci.c_customer_sk,
           ci.c_first_name,
           ci.c_last_name,
           ci.c_birth_month,
           ci.cd_gender,
           si.total_sales,
           si.total_orders,
           si.average_net_paid,
           CASE 
               WHEN ci.num_returns > 2 THEN 'High return customer'
               WHEN si.total_sales IS NULL THEN 'No sales'
               ELSE 'Regular customer'
           END AS customer_status
    FROM customer_info ci
    LEFT JOIN sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT *,
       ROW_NUMBER() OVER (PARTITION BY c_birth_month ORDER BY total_sales DESC NULLS LAST) AS sales_rank,
       COALESCE(total_orders, 0) + COALESCE(num_returns, 0) AS interaction_total,
       CONCAT(c_first_name, ' ', c_last_name) AS full_name,
       CASE
           WHEN c_birth_month < 6 THEN 'First Half'
           WHEN c_birth_month >= 6 THEN 'Second Half'
           ELSE 'Unknown'
       END AS birth_half
FROM combined_info
WHERE (customer_status = 'Regular customer' AND total_sales > 1000)
   OR (customer_status = 'High return customer' AND average_net_paid < 50)
ORDER BY total_sales DESC, c_birth_month ASC;
