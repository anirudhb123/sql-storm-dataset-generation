
WITH CustomerSales AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           SUM(ws.ws_net_paid) AS total_spent,
           COUNT(ws.ws_order_number) AS order_count,
           AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
           MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           total_spent,
           order_count,
           avg_order_value,
           last_purchase_date
    FROM CustomerSales
    WHERE total_spent > (SELECT AVG(total_spent) FROM CustomerSales)
    ORDER BY total_spent DESC
    LIMIT 10
),
CustomerDemographics AS (
    SELECT cd.cd_demo_sk,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_education_status,
           tc.c_first_name,
           tc.c_last_name,
           tc.total_spent,
           tc.order_count,
           tc.avg_order_value,
           tc.last_purchase_date
    FROM customer_demographics cd
    JOIN TopCustomers tc ON cd.cd_demo_sk = c.c_current_cdemo_sk
)
SELECT cd.cd_gender,
       cd.cd_marital_status,
       COUNT(*) AS customer_count,
       AVG(tc.total_spent) AS avg_total_spent,
       AVG(tc.order_count) AS avg_order_count,
       MAX(tc.last_purchase_date) AS most_recent_purchase
FROM CustomerDemographics cd
JOIN TopCustomers tc ON cd.c_first_name = tc.c_first_name AND cd.c_last_name = tc.c_last_name
GROUP BY cd.cd_gender, cd.cd_marital_status
ORDER BY avg_total_spent DESC;
