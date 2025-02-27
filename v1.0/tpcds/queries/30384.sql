
WITH RECURSIVE Sales_CTE AS (
    SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity, SUM(ws_net_profit) AS total_profit
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY ws_item_sk

    UNION ALL

    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) + sc.total_quantity, SUM(ws.ws_net_profit) + sc.total_profit
    FROM web_sales ws
    JOIN Sales_CTE sc ON ws.ws_item_sk = sc.ws_item_sk
    WHERE ws.ws_sold_date_sk < (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2021)
    GROUP BY ws.ws_item_sk, sc.total_quantity, sc.total_profit
),
Customer_Stats AS (
    SELECT cd_gender, COUNT(DISTINCT c_customer_id) AS customer_count,
           AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender
)
SELECT ca.ca_city,
       SUM(CASE WHEN ss.ss_item_sk IS NOT NULL THEN ss.ss_net_paid ELSE 0 END) AS total_store_sales,
       AVG(ws.ws_net_profit) AS avg_web_sales_profit,
       cs.customer_count,
       cs.avg_purchase_estimate
FROM store s
LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
FULL OUTER JOIN web_sales ws ON ss.ss_item_sk = ws.ws_item_sk
JOIN Customer_Stats cs ON cs.customer_count > 100
JOIN customer_address ca ON ca.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = ss.ss_customer_sk)
GROUP BY ca.ca_city, cs.customer_count, cs.avg_purchase_estimate
HAVING SUM(ss.ss_net_paid) > 10000 OR AVG(ws.ws_net_profit) > 50
ORDER BY ca.ca_city, total_store_sales DESC;
