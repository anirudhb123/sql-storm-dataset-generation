
WITH RECURSIVE address_cte AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country,
           ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS rn
    FROM customer_address
    WHERE ca_country IS NOT NULL
),
detailed_sales AS (
    SELECT ws.web_site_id, ws.ws_order_number,
           COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales,
           COUNT(DISTINCT ws.ws_item_sk) AS total_items,
           DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2022
    GROUP BY ws.web_site_id, ws.ws_order_number
    HAVING COUNT(DISTINCT ws.ws_item_sk) > 5
),
customer_summary AS (
    SELECT c.c_customer_id,
           cd.cd_marital_status,
           cd.cd_gender,
           ci.c_birth_month,
           AVG(ws.ws_net_paid) OVER (PARTITION BY c.c_customer_sk) AS avg_net_paid,
           COALESCE(MAX(ws.ws_ext_discount_amt), 0) AS max_discount
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN (SELECT DISTINCT 
                 c.c_customer_sk, 
                 EXTRACT(MONTH FROM c.c_birth_month) AS c_birth_month
          FROM customer c) ci ON ci.c_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id, cd.cd_marital_status, cd.cd_gender, ci.c_birth_month
),
complex_sales_summary AS (
    SELECT d.date_id, s.state,
           SUM(COALESCE(ss.ss_sales_price, 0)) AS total_store_sales,
           SUM(COALESCE(cs.cs_sales_price, 0)) AS total_catalog_sales,
           SUM(COALESCE(ws.ws_sales_price, 0)) AS total_web_sales,
           ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_sales_price) DESC) AS sales_rank
    FROM date_dim d
    FULL OUTER JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    FULL OUTER JOIN catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    FULL OUTER JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    JOIN customer_address ca ON ca.ca_city = d.d_month_seq::text
    JOIN income_band ib ON ib.ib_income_band_sk = (
        SELECT ib_income_band_sk FROM household_demographics hd 
        WHERE hd.hd_demo_sk = (SELECT c.c_current_hdemo_sk FROM customer c WHERE c.c_customer_sk = 1)
    )
    WHERE d.d_year >= 2020
    GROUP BY d.date_id, s.state
)
SELECT a.ca_city, a.ca_state, 
       SUM(cs.avg_net_paid) AS total_avg_net,
       COUNT(DISTINCT cs.c_customer_id) AS unique_customers,
       SUM(DISTINCT css.total_store_sales) AS grand_total_sales
FROM address_cte a
JOIN customer_summary cs ON a.rn = cs.c_birth_month
LEFT JOIN complex_sales_summary css ON css.state = a.ca_state
WHERE a.ca_city IS NOT NULL AND a.ca_state IS NOT NULL
GROUP BY a.ca_city, a.ca_state
HAVING COUNT(cs.c_customer_id) > 10
ORDER BY total_avg_net DESC;
