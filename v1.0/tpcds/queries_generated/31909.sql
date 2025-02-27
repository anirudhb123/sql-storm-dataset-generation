
WITH RECURSIVE sales_hierarchy AS (
    SELECT ss_customer_sk, SUM(ss_net_profit) AS total_profit
    FROM store_sales
    GROUP BY ss_customer_sk
    HAVING SUM(ss_net_profit) > 10000
    UNION ALL
    SELECT c.c_customer_sk, sh.total_profit + COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit
    FROM sales_hierarchy sh
    JOIN customer c ON c.c_customer_sk = sh.ss_customer_sk
    LEFT JOIN web_sales ws ON ws.ws_ship_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, sh.total_profit
),
customer_info AS (
    SELECT c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, ca.ca_city,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ss_net_profit) DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE cd.cd_marital_status = 'M'
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, ca.ca_city
    HAVING COUNT(ss.ss_sales_price) > 5
),
top_customers AS (
    SELECT ci.c_customer_id, ci.c_first_name, ci.c_last_name, ci.ca_city,
           sh.total_profit
    FROM customer_info ci
    JOIN sales_hierarchy sh ON ci.c_customer_id = sh.ss_customer_sk
    WHERE ci.gender_rank <= 10
)
SELECT DISTINCT
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.ca_city,
    CASE 
        WHEN tc.total_profit IS NULL THEN 'No Profit'
        ELSE CONCAT('Total Profit: $', ROUND(tc.total_profit, 2))
    END AS profit_status
FROM top_customers tc
LEFT JOIN web_returns wr ON wr.wr_returning_customer_sk = tc.c_customer_id
WHERE wr.wr_return_date_sk IS NULL
OR wr.wr_return_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022);
