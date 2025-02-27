
WITH RECURSIVE customer_ranked AS (
    SELECT c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_country, 
           COUNT(ws.ws_order_number) AS order_count,
           RANK() OVER (PARTITION BY cd.cd_gender ORDER BY COUNT(ws.ws_order_number) DESC) AS gender_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_country
),
sales_summary AS (
    SELECT sd.d_date, SUM(ws.ws_sales_price) AS total_sales,
           SUM(ws.ws_net_profit) AS total_profit,
           SUM(ws.ws_net_paid_inc_tax) AS total_paid
    FROM date_dim sd
    JOIN web_sales ws ON sd.d_date_sk = ws.ws_sold_date_sk
    GROUP BY sd.d_date
),
address_summary AS (
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, COUNT(c.c_customer_sk) AS city_customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT r.c_customer_id, r.cd_gender, r.city_customer_count, r.total_sales, r.total_profit,
       COALESCE(SUM(s.total_paid), 0) AS total_paid,
       CASE 
           WHEN r.order_count > 5 THEN 'High Value Customer'
           ELSE 'Regular Customer'
       END AS customer_category
FROM customer_ranked r
LEFT JOIN sales_summary s ON r.order_count > 0
LEFT JOIN address_summary a ON r.c_customer_id = a.ca_address_sk
GROUP BY r.c_customer_id, r.cd_gender, r.city_customer_count, r.total_sales, r.total_profit, r.order_count
HAVING city_customer_count IS NOT NULL AND r.cd_gender IS NOT NULL
ORDER BY total_profit DESC NULLS LAST, total_sales DESC;
