
WITH RECURSIVE customer_data AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           cd.cd_gender, cd.cd_marital_status, cd.cd_buy_potential, 
           cd.cd_dep_count, cd.cd_dep_emp_count, 
           ROW_NUMBER() OVER (PARTITION BY c.c_current_cdemo_sk ORDER BY c.c_birth_year DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_dep_count IS NOT NULL
),
sales_data AS (
    SELECT ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_sales_price, ws.ws_net_profit, 
           CASE 
               WHEN ws.ws_sales_price IS NULL THEN 0
               ELSE ROUND(ws.ws_net_profit / NULLIF(ws.ws_sales_price, 0), 2)
           END AS profit_margin
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    UNION ALL
    SELECT cs.cs_sold_date_sk, cs.cs_item_sk, cs.cs_sales_price, cs.cs_net_profit, 
           CASE 
               WHEN cs.cs_sales_price IS NULL THEN 0
               ELSE ROUND(cs.cs_net_profit / NULLIF(cs.cs_sales_price, 0), 2)
           END AS profit_margin
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk < (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
),
address_info AS (
    SELECT ca.ca_city, ca.ca_state, COUNT(DISTINCT c.c_customer_sk) AS total_customers
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_city, ca.ca_state
)
SELECT addr.ca_city, addr.ca_state, 
       COALESCE(cd.c_first_name || ' ' || cd.c_last_name, 'Unknown Customer') AS customer_name,
       COUNT(s.ws_item_sk) AS item_sales,
       SUM(s.profit_margin) AS total_profit_margin,
       MAX(s.ws_sales_price) AS highest_sales_price
FROM address_info addr
LEFT JOIN customer_data cd ON addr.total_customers > 0 AND cd.rn = 1
LEFT JOIN sales_data s ON s.ws_item_sk = cd.c_current_cdemo_sk 
WHERE addr.total_customers IS NOT NULL
GROUP BY addr.ca_city, addr.ca_state, customer_name
HAVING COUNT(s.ws_item_sk) > CASE WHEN addr.total_customers = 0 THEN 1 ELSE 0 END
ORDER BY total_profit_margin DESC NULLS LAST;
