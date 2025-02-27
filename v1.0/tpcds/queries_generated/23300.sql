
WITH RECURSIVE wealthier_customers AS (
    SELECT c.c_customer_sk, c.c_customer_id, cd.cd_marital_status, cd.cd_buy_potential,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(CASE WHEN ws.ws_quantity > 0 THEN ws.ws_net_profit ELSE 0 END) DESC) as wealth_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_purchase_estimate > 1000
    GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status
    HAVING SUM(CASE WHEN ws.ws_quantity > 0 THEN ws.ws_net_profit ELSE 0 END) IS NOT NULL
),
address_info AS (
    SELECT DISTINCT ca.ca_city, ca.ca_state, ca.ca_country,
           COUNT(DISTINCT c.c_customer_sk) AS customer_count, 
           AVG(cd.cd_dep_count) AS avg_dependents
    FROM customer_address ca
    JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY ca.ca_city, ca.ca_state, ca.ca_country
),
sales_summary AS (
    SELECT SUM(ss.ss_ext_sales_price) AS total_sales, 
           ss.ss_sold_date_sk, 
           DENSE_RANK() OVER (ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM store_sales ss
    JOIN warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    WHERE w.w_warehouse_sq_ft > 10000
    GROUP BY ss.ss_sold_date_sk
)
SELECT ac.ca_city, ac.ca_state, ac.ca_country, 
       SUM(COALESCE(ws.ws_net_profit, 0)) AS total_profit,
       COUNT(DISTINCT wc.c_customer_id) AS wealthy_customers,
       MAX(CASE WHEN rank.sales_rank = 1 THEN rank.total_sales ELSE 0 END) AS highest_daily_sales
FROM address_info ac
LEFT JOIN wealthier_customers wc ON ac.customer_count > 10
LEFT JOIN sales_summary rank ON 1=1 
LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk IN (SELECT c.c_customer_sk FROM wealthier_customers c)
WHERE ac.customer_count IS NOT NULL
GROUP BY ac.ca_city, ac.ca_state, ac.ca_country
HAVING SUM(COALESCE(ws.ws_net_profit, 0)) > 5000 OR COUNT(DISTINCT wc.c_customer_id) > 5
ORDER BY total_profit DESC, wealthy_customers ASC
LIMIT 100;
