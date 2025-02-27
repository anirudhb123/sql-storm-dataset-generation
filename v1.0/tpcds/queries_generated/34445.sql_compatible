
WITH RECURSIVE revenue_by_customer AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           COALESCE(SUM(ws.ws_net_paid), 0) AS total_revenue
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    UNION ALL
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           COALESCE(SUM(cs.cs_net_paid), 0) + rb.total_revenue
    FROM customer c
    JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN revenue_by_customer rb ON c.c_customer_sk = rb.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, rb.total_revenue
),
ranked_customers AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           rb.total_revenue,
           DENSE_RANK() OVER (ORDER BY rb.total_revenue DESC) AS revenue_rank
    FROM revenue_by_customer rb
    JOIN customer c ON rb.c_customer_sk = c.c_customer_sk
),
top_customers AS (
    SELECT *
    FROM ranked_customers
    WHERE revenue_rank <= 10
),
customer_info AS (
    SELECT tc.c_customer_sk,
           tc.c_first_name,
           tc.c_last_name,
           tc.total_revenue,
           CASE 
               WHEN cd.cd_gender = 'M' THEN 'Male'
               WHEN cd.cd_gender = 'F' THEN 'Female'
               ELSE 'Other'
           END AS gender,
           ca.ca_city,
           ca.ca_state
    FROM top_customers tc
    LEFT JOIN customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON ca.ca_address_sk = tc.c_customer_sk
)
SELECT DISTINCT ci.c_first_name,
       ci.c_last_name,
       ci.total_revenue,
       ci.gender,
       ci.ca_city,
       ci.ca_state,
       (SELECT COUNT(DISTINCT ws.ws_order_number)
        FROM web_sales ws
        WHERE ws.ws_bill_customer_sk = ci.c_customer_sk) AS total_orders,
       (SELECT COUNT(DISTINCT cs.cs_order_number)
        FROM catalog_sales cs
        WHERE cs.cs_bill_customer_sk = ci.c_customer_sk) AS total_catalog_orders,
       NULLIF((SELECT SUM(cr.cr_return_amount)
                FROM catalog_returns cr
                WHERE cr.cr_returning_customer_sk = ci.c_customer_sk), 0) AS total_catalog_returns,
       COALESCE((SELECT SUM(ws.ws_net_paid_inc_tax)
                  FROM web_sales ws
                  WHERE ws.ws_ship_customer_sk = ci.c_customer_sk), 0) AS total_web_payments
FROM customer_info ci
ORDER BY ci.total_revenue DESC;
