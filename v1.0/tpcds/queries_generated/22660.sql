
WITH RECURSIVE customer_statistics AS (
    SELECT c_customer_sk,
           c_customer_id,
           COALESCE(SUM(ws_quantity), 0) AS total_quantity,
           COALESCE(SUM(ws_net_profit), 0) AS total_net_profit,
           ROW_NUMBER() OVER (ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM customer
    LEFT JOIN web_sales ON c_customer_sk = ws_bill_customer_sk
    GROUP BY c_customer_sk, c_customer_id
),
address_summary AS (
    SELECT ca_state,
           COUNT(DISTINCT c_customer_sk) AS customer_count,
           AVG(total_net_profit) AS avg_net_profit
    FROM customer_address
    JOIN customer ON c_current_addr_sk = ca_address_sk
    JOIN customer_statistics ON c_customer_sk = c_customer_sk
    GROUP BY ca_state
),
demographics AS (
    SELECT cd_gender,
           COUNT(DISTINCT cd_demo_sk) AS demographic_count,
           SUM(cd_dep_count) AS total_dependencies
    FROM customer_demographics
    GROUP BY cd_gender
),
item_sales AS (
    SELECT i_item_sk,
           i_item_id,
           SUM(ss_quantity) AS total_sold,
           AVG(ss_sales_price) AS avg_price
    FROM item
    LEFT JOIN store_sales ON i_item_sk = ss_item_sk
    GROUP BY i_item_sk, i_item_id
)
SELECT a.ca_state,
       a.customer_count,
       COALESCE(a.avg_net_profit, 0) AS avg_net_profit,
       d.cd_gender,
       d.demographic_count,
       d.total_dependencies,
       i.total_sold,
       i.avg_price
FROM address_summary a
FULL OUTER JOIN demographics d ON a.customer_count > 50 AND d.cd_gender IS NOT NULL
FULL OUTER JOIN item_sales i ON i.total_sold > 100 OR (i.total_sold IS NULL AND i.avg_price > 20)
WHERE (a.customer_count > 0 OR d.demographic_count > 0)
AND (COALESCE(i.total_sold, 0) > 0 OR i.avg_price IS NOT NULL)
ORDER BY a.ca_state, d.cd_gender, i.total_sold DESC;
