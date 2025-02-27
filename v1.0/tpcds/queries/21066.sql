
WITH RECURSIVE date_range AS (
    SELECT MIN(d_date_sk) AS start_date, MAX(d_date_sk) AS end_date
    FROM date_dim
),
increment AS (
    SELECT start_date AS d_date_sk
    FROM date_range
    UNION ALL
    SELECT d_date_sk + 1
    FROM increment
    WHERE d_date_sk < (SELECT end_date FROM date_range)
),
customer_data AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           ROW_NUMBER() OVER(PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 1000
),
sales_data AS (
    SELECT ws.ws_sold_date_sk,
           SUM(ws.ws_net_profit) AS total_net_profit,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk IS NOT NULL
    GROUP BY ws.ws_sold_date_sk
),
annual_sales AS (
    SELECT d.d_year,
           SUM(sd.total_net_profit) AS annual_net_profit,
           SUM(sd.total_orders) AS annual_orders
    FROM date_dim d
    LEFT JOIN sales_data sd ON d.d_date_sk = sd.ws_sold_date_sk
    GROUP BY d.d_year
)
SELECT c.c_first_name,
       c.c_last_name,
       c.cd_gender,
       ar.annual_net_profit,
       ar.annual_orders,
       CASE 
           WHEN ar.annual_net_profit IS NULL THEN 'No Sales'
           WHEN ar.annual_net_profit < 5000 THEN 'Low Performer'
           ELSE 'High Performer'
       END AS performance_rating
FROM customer_data c
JOIN annual_sales ar ON c.c_customer_sk = (SELECT sd.ws_bill_customer_sk
                                           FROM web_sales sd
                                           JOIN date_dim dd ON sd.ws_sold_date_sk = dd.d_date_sk
                                           WHERE dd.d_year = ar.d_year
                                           LIMIT 1)
WHERE c.purchase_rank <= 5
  AND c.cd_gender IN ('M', 'F')
  AND ar.annual_orders > 0
ORDER BY ar.annual_net_profit DESC
LIMIT 10;
