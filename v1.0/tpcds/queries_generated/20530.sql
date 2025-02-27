
WITH RECURSIVE address_cte AS (
    SELECT ca_address_sk,
           ca_city,
           ca_state,
           1 AS level
    FROM customer_address
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT ca.ca_address_sk,
           ca.ca_city,
           ca.ca_state,
           ac.level + 1
    FROM customer_address ca
    JOIN address_cte ac ON ca.ca_city = ac.ca_city
    WHERE ac.level < 5 AND ca.ca_state IS NOT NULL
),
income_info AS (
    SELECT cd.cd_demo_sk,
           MAX(CASE WHEN cd.hd_income_band_sk IS NULL THEN 'UNKNOWN' ELSE 'KNOWN' END) AS income_status,
           COUNT(DISTINCT cd.hd_demo_sk) AS demographic_count
    FROM household_demographics cd
    GROUP BY cd.cd_demo_sk
),
sales_info AS (
    SELECT ws.warehouse_sk,
           SUM(ws.ws_net_profit) AS total_profit,
           AVG(ws.ws_list_price) AS avg_price,
           COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.warehouse_sk
),
return_stats AS (
    SELECT sr_store_sk,
           SUM(sr_return_quantity) AS total_returns,
           COUNT(DISTINCT sr_ticket_number) AS unique_returns
    FROM store_returns sr
    GROUP BY sr_store_sk
)
SELECT a.city,
       a.state,
       i.income_status,
       s.total_profit,
       r.total_returns,
       RANK() OVER (PARTITION BY a.state ORDER BY s.total_profit DESC) AS profit_rank,
       CASE WHEN s.order_count > 100 THEN 'High Volume' ELSE 'Low Volume' END AS sales_volume_category
FROM address_cte a
LEFT JOIN income_info i ON a.ca_address_sk = i.cd_demo_sk
JOIN sales_info s ON s.warehouse_sk = a.ca_address_sk
FULL OUTER JOIN return_stats r ON r.sr_store_sk = s.warehouse_sk
WHERE (i.income_status IS NOT NULL OR a.level <= 3)
  AND COALESCE(r.total_returns, 0) < 50
ORDER BY profit_rank, a.city DESC NULLS LAST;
