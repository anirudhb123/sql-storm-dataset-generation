
WITH RECURSIVE top_customers AS (
    SELECT c.c_customer_sk, 
           c.c_first_name || ' ' || c.c_last_name AS customer_name, 
           SUM(ss.ss_net_profit) AS total_profit
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, customer_name
    HAVING SUM(ss.ss_net_profit) > 1000
    ORDER BY total_profit DESC
    LIMIT 5
),
sales_summary AS (
    SELECT s.s_store_sk, 
           SUM(ws.ws_ext_sales_price) AS total_sales,
           AVG(ws.ws_ext_sales_price) AS avg_sales,
           MAX(ws.ws_sales_price) AS max_sale
    FROM web_sales ws
    JOIN store s ON ws.ws_store_sk = s.s_store_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk 
                                  FROM date_dim 
                                  WHERE d_year = 2023 AND d_moy = 10)
    GROUP BY s.s_store_sk
),
revenue_by_city AS (
    SELECT ca.ca_city,
           SUM(ss.ss_net_paid) AS total_revenue,
           COUNT(DISTINCT c.c_customer_sk) AS unique_customers
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_city
    HAVING SUM(ss.ss_net_paid) IS NOT NULL
),
customer_demographics AS (
    SELECT cd.cd_gender,
           cd.cd_marital_status,
           COUNT(*) AS customer_count,
           AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
)
SELECT tc.customer_name,
       ss.total_sales,
       ss.avg_sales,
       rb.city_revenue,
       cd.cd_gender,
       cd.cd_marital_status
FROM top_customers tc
LEFT JOIN sales_summary ss ON tc.c_customer_sk = ss.s_store_sk
LEFT JOIN (
    SELECT ca.ca_city AS city,
           revenue.total_revenue
    FROM revenue_by_city revenue
) rb ON rb.city = tc.city
JOIN customer_demographics cd ON cd.customer_count = (SELECT MAX(customer_count)
                                                      FROM customer_demographics)
ORDER BY ss.total_sales DESC, rb.total_revenue DESC;
