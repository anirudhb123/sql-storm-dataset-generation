
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, 1 AS level
    FROM customer_address
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT ca ca_address_sk, ca_city, ca_state, level + 1
    FROM customer_address a
    JOIN address_hierarchy h ON a.ca_address_sk = h.ca_address_sk
    WHERE h.level < 5
),
customer_ages AS (
    SELECT c.c_customer_sk,
           EXTRACT(YEAR FROM CURRENT_DATE) - c.c_birth_year AS age,
           cd.cd_gender,
           cd.cd_marital_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_net_profit) AS total_net_profit,
           COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL
    GROUP BY ws_bill_customer_sk
),
return_summary AS (
    SELECT sr_customer_sk,
           SUM(sr_return_amt) AS total_return_amt,
           COUNT(sr_returned_date_sk) AS total_returns
    FROM store_returns
    GROUP BY sr_customer_sk
    HAVING total_return_amt > 100
),
final_summary AS (
    SELECT ca.ca_city,
           ca.ca_state,
           c.c_customer_sk,
           c.ages,
           COALESCE(ss.total_net_profit, 0) AS web_sales_profit,
           COALESCE(rs.total_return_amt, 0) AS store_return_amt,
           (COALESCE(ss.total_net_profit, 0) - COALESCE(rs.total_return_amt, 0)) AS net_profit_after_returns
    FROM address_hierarchy ca
    FULL OUTER JOIN customer_ages c ON c.c_customer_sk = ca.ca_address_sk
    LEFT JOIN sales_summary ss ON ss.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN return_summary rs ON rs.sr_customer_sk = c.c_customer_sk
)
SELECT f.ca_city,
       f.ca_state,
       f.net_profit_after_returns,
       COUNT(DISTINCT f.c_customer_sk) AS customer_count
FROM final_summary f
WHERE f.net_profit_after_returns > 0
GROUP BY f.ca_city, f.ca_state
ORDER BY f.net_profit_after_returns DESC
LIMIT 10;
