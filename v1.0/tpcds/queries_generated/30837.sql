
WITH RECURSIVE top_customers AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk >= 2459580 -- Assuming this is some date in the past
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(ws.ws_net_paid) > 1000
    ORDER BY total_spent DESC
    LIMIT 10
),
daily_sales AS (
    SELECT dd.d_date, 
           SUM(ws.ws_net_paid) AS daily_net_sales
    FROM date_dim dd
    LEFT JOIN web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    WHERE dd.d_year = 2023
    GROUP BY dd.d_date
),
customer_demographics AS (
    SELECT cd.cd_demo_sk,
           cd.cd_gender,
           cd.cd_marital_status,
           COUNT(c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT tc.c_first_name,
       tc.c_last_name,
       cd.cd_gender,
       cd.cd_marital_status,
       ds.daily_net_sales,
       COALESCE(ds.daily_net_sales, 0) AS net_sales_or_zero,
       CASE WHEN cd.cd_gender = 'F' THEN 'Female'
            WHEN cd.cd_gender = 'M' THEN 'Male'
            ELSE 'Other' END AS gender_description
FROM top_customers tc
LEFT JOIN customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
LEFT JOIN (
    SELECT d.d_date, 
           SUM(daily_net_sales) AS total_daily_sales
    FROM daily_sales d
    GROUP BY d.d_date
) ds ON ds.d_date = CURRENT_DATE -- Assuming we want today's sales
WHERE tc.total_spent > (SELECT AVG(total_spent) FROM top_customers)
ORDER BY tc.total_spent DESC
LIMIT 50;
