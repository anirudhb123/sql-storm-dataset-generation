
WITH RECURSIVE sales_cte AS (
    SELECT ws_item_sk, 
           SUM(ws_ext_sales_price) AS total_sales,
           COUNT(ws_order_number) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank_sales
    FROM web_sales
    WHERE ws_sold_date_sk >= 2452000 AND ws_sold_date_sk <= 2452070
    GROUP BY ws_item_sk
),
customer_info AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status,
           cd.cd_credit_rating,
           (SELECT COUNT(*) FROM customer_address ca WHERE ca.ca_address_sk = c.c_current_addr_sk) AS address_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status IS NOT NULL
)
SELECT ci.c_customer_sk,
       ci.c_first_name,
       ci.c_last_name,
       ci.cd_gender,
       ci.cd_marital_status,
       ss.sales_total, 
       ss.order_count,
       CASE 
           WHEN ss.sales_total > 1000 THEN 'High Value'
           WHEN ss.sales_total BETWEEN 500 AND 1000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS customer_value,
       (CASE 
            WHEN ci.address_count IS NULL THEN 'No Address'
            ELSE 'Address Exists'
        END) AS address_status
FROM customer_info ci
LEFT JOIN (
    SELECT s.ss_customer_sk, 
           SUM(s.ss_ext_sales_price) AS sales_total, 
           COUNT(s.ss_ticket_number) AS ticket_count
    FROM store_sales s
    WHERE s.ss_sold_date_sk BETWEEN 2452000 AND 2452070
    GROUP BY s.ss_customer_sk
) ss ON ci.c_customer_sk = ss.ss_customer_sk
FULL OUTER JOIN sales_cte sc ON sc.ws_item_sk IN (SELECT si.ss_item_sk FROM store_sales si WHERE si.ss_customer_sk = ci.c_customer_sk)
WHERE ci.cd_credit_rating IS NOT NULL
  AND (ci.cd_gender = 'F' OR ci.cd_gender IS NULL)
ORDER BY customer_value DESC, total_sales DESC
LIMIT 100;
