
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_zip, 1 AS level
    FROM customer_address
    WHERE ca_city IS NOT NULL
    UNION ALL
    SELECT a.ca_address_sk, a.ca_city, a.ca_state, a.ca_zip, ah.level + 1
    FROM customer_address a
    JOIN address_hierarchy ah ON a.ca_city = ah.ca_city
    WHERE ah.level < 5
),
customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, 
           cd.cd_income_band_sk, cd.cd_marital_status, 
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_marital_status IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_income_band_sk, cd.cd_marital_status
),
sales_summary AS (
    SELECT c.c_customer_sk,
           SUM(cs.cs_quantity) AS total_quantity,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           (SUM(cs.cs_ext_sales_price) - SUM(cs.cs_ext_wholesale_cost)) AS total_margin
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT ci.c_first_name || ' ' || ci.c_last_name AS customer_name,
       ci.cd_gender,
       COUNT(DISTINCT ah.ca_address_sk) AS address_count,
       ci.total_orders,
       ci.total_profit,
       ss.total_quantity,
       ss.total_sales,
       ss.total_margin
FROM customer_info ci
LEFT JOIN address_hierarchy ah ON ci.c_customer_sk = ah.ca_address_sk
LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.c_customer_sk
WHERE coalesce(ss.total_sales, 0) > 1000
GROUP BY ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.total_orders, ci.total_profit
ORDER BY total_profit DESC
LIMIT 100;
