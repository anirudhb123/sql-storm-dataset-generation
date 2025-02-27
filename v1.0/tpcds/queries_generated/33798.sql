
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    INNER JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
SalesData AS (
    SELECT ws_bill_customer_sk AS customer_sk, 
           SUM(ws_net_paid_inc_tax) AS total_spent, 
           COUNT(ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
),
TopCustomers AS (
    SELECT cd.cd_demo_sk,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_education_status,
           ch.level,
           COALESCE(sd.total_spent, 0) AS total_spent,
           sd.total_orders
    FROM customer_demographics cd
    LEFT JOIN CustomerHierarchy ch ON cd.cd_demo_sk = ch.c_current_cdemo_sk
    LEFT JOIN SalesData sd ON cd.cd_demo_sk = sd.customer_sk
    WHERE cd.cd_marital_status = 'M' AND cd.cd_gender = 'F'  -- Filter for married females
)
SELECT DISTINCT c.c_customer_id,
                c.c_first_name,
                c.c_last_name,
                cc.ca_city,
                cc.ca_state,
                tc.total_spent,
                tc.total_orders,
                CASE 
                    WHEN tc.total_spent >= 1000 THEN 'High Value'
                    WHEN tc.total_spent BETWEEN 500 AND 999 THEN 'Medium Value'
                    ELSE 'Low Value'
                END AS customer_value
FROM customer c
JOIN customer_address cc ON c.c_current_addr_sk = cc.ca_address_sk
JOIN TopCustomers tc ON tc.cd_demo_sk = c.c_current_cdemo_sk
WHERE (tc.total_orders > 5 OR tc.total_spent > 500)
ORDER BY customer_value DESC, tc.total_spent DESC
FETCH FIRST 100 ROWS ONLY;
