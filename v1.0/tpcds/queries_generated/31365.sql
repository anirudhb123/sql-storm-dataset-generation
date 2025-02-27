
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_preferred_cust_flag, 0 AS level
    FROM customer
    WHERE c_preferred_cust_flag = 'Y'
    
    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
sales_data AS (
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_quantity,
           ws.ws_sales_price,
           SUM(ws.ws_net_paid) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_paid
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 10000 AND 10005
),
joined_data AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           COALESCE(sd.cumulative_net_paid, 0) AS total_net_paid,
           cd.cd_gender,
           cd.cd_marital_status,
           ca.ca_city,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY total_net_paid DESC) AS rn
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN sales_data sd ON c.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT j.c_customer_sk,
       j.c_first_name,
       j.c_last_name,
       j.total_net_paid,
       j.cd_gender,
       j.ca_city,
       CASE 
           WHEN j.cd_marital_status = 'M' THEN 'Married'
           WHEN j.cd_marital_status = 'S' THEN 'Single'
           ELSE 'Other'
       END AS marital_status,
       h.level AS hierarchy_level
FROM joined_data j
JOIN customer_hierarchy h ON j.c_customer_sk = h.c_customer_sk
WHERE j.rn <= 5 AND j.total_net_paid > 1000
ORDER BY j.total_net_paid DESC NULLS LAST;
