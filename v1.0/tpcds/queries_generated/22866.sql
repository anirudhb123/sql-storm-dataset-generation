
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_address_id, ca_city, ca_state, ca_country,
           ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS rn
    FROM customer_address
    WHERE ca_city IS NOT NULL
),
ranked_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name,
           cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_first_name) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
most_frequent_sales AS (
    SELECT ws_bill_customer_sk, COUNT(*) AS sales_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
    HAVING COUNT(*) > (SELECT AVG(sales_count) FROM (SELECT COUNT(*) AS sales_count FROM web_sales GROUP BY ws_bill_customer_sk))
),
total_sales AS (
    SELECT ws_bill_customer_sk, SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
customer_address_info AS (
    SELECT ca.ca_address_id, ca.ca_city, ca.ca_state, ws.ws_bill_customer_sk
    FROM customer_address ca
    LEFT JOIN web_sales ws ON ca.ca_address_sk = ws.ws_bill_addr_sk
    WHERE ca.ca_country = 'USA' AND ws.ws_bill_customer_sk IS NOT NULL
)
SELECT COALESCE(c.c_first_name || ' ' || c.c_last_name, 'Unknown Customer') AS customer_name,
       SUM(COALESCE(ws.ws_net_profit, 0)) AS total_profit,
       COUNT(DISTINCT ws.ws_order_number) AS total_orders,
       (SELECT COUNT(*) FROM address_hierarchy a WHERE a.ca_city = ca.ca_city) AS city_count,
       (SELECT STRING_AGG(DISTINCT ib.ib_upper_bound::TEXT, ', ') 
        FROM income_band ib 
        JOIN household_demographics hd ON ib.ib_income_band_sk = hd.hd_income_band_sk 
        WHERE hd.hd_dep_count > 2 AND hd.hd_buy_potential = 'High') AS high_income_bands,
       rank.gender_rank,
       RANK() OVER (ORDER BY SUM(COALESCE(ws.ws_net_profit, 0)) DESC) AS profit_rank
FROM ranked_customers rank
JOIN web_sales ws ON rank.c_customer_sk = ws.ws_bill_customer_sk
JOIN customer_address_info ca ON ws.ws_bill_addr_sk = ca.ca_address_id
JOIN total_sales ts ON ts.ws_bill_customer_sk = rank.c_customer_sk
WHERE ws.ws_net_profit IS NOT NULL AND rank.gender_rank < 10
GROUP BY c.customer_name, rank.gender_rank
ORDER BY total_profit DESC, profit_rank;
