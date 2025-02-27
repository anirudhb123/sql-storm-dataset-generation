
WITH RECURSIVE income_hierarchy AS (
    SELECT hd_demo_sk, ib_income_band_sk, hd_buy_potential, hd_dep_count, 
           CAST(NULL AS decimal(10,2)) AS cumulative_income
    FROM household_demographics 
    LEFT JOIN income_band ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
    WHERE hd_buy_potential IS NOT NULL
    UNION ALL
    SELECT h.hd_demo_sk, h.ib_income_band_sk, h.hd_buy_potential, h.hd_dep_count, 
           h.hd_dep_count * COALESCE(i.ib_upper_bound, 0) + COALESCE(income_hierarchy.cumulative_income, 0)
    FROM household_demographics h
    JOIN income_hierarchy ON h.hd_demo_sk = income_hierarchy.hd_demo_sk
),
total_sales AS (
    SELECT ws_bill_customer_sk, 
           SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
demographic_sales AS (
    SELECT c.c_customer_id, 
           d.cd_gender, 
           d.cd_marital_status, 
           SUM(s.ws_net_profit) AS total_sales_profit
    FROM customer c 
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN total_sales s ON c.c_customer_sk = s.ws_bill_customer_sk
    WHERE d.cd_marital_status = 'M'
    GROUP BY c.c_customer_id, d.cd_gender, d.cd_marital_status
),
customer_info AS (
    SELECT c.c_customer_sk, 
           ca.ca_country,
           ds.total_sales_profit,
           ROW_NUMBER() OVER (PARTITION BY ca.ca_country ORDER BY ds.total_sales_profit DESC) AS country_rank
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN demographic_sales ds ON c.c_customer_sk = ds.c_customer_id
),
ranked_customers AS (
    SELECT * 
    FROM customer_info
    WHERE country_rank <= 10
)

SELECT r.ca_country, 
       COUNT(r.c_customer_sk) AS top_customers_count, 
       SUM(COALESCE(r.total_sales_profit, 0)) AS total_profit
FROM ranked_customers r
GROUP BY r.ca_country
ORDER BY total_profit DESC;

