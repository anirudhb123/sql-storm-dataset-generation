
WITH RECURSIVE sales_hierarchy AS (
    SELECT ws_bill_customer_sk, 
           SUM(ws_net_profit) AS total_profit,
           COUNT(ws_order_number) AS total_orders,
           RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
    UNION ALL
    SELECT s.ws_bill_customer_sk, 
           s.ws_net_profit + sh.total_profit,
           1 + sh.total_orders,
           RANK() OVER (ORDER BY (s.ws_net_profit + sh.total_profit) DESC)
    FROM web_sales s
    JOIN sales_hierarchy sh ON s.ws_bill_customer_sk = sh.ws_bill_customer_sk
    WHERE sh.total_orders < 5 
)
SELECT s.ws_bill_customer_sk, 
       c.c_first_name || ' ' || c.c_last_name AS customer_name,
       sh.total_profit AS accumulated_profit,
       sh.total_orders AS number_of_orders,
       COALESCE(i.ib_income_band_sk, -1) AS income_band_id,
       d.d_year,
       CASE 
           WHEN d.d_year = 2023 THEN 'Current Year'
           WHEN d.d_year = 2022 THEN 'Last Year'
           ELSE 'Earlier'
       END AS year_label,
       COUNT(DISTINCT i.i_item_sk) AS unique_items_purchased
FROM sales_hierarchy sh
JOIN customer c ON c.c_customer_sk = sh.ws_bill_customer_sk
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
LEFT JOIN inventory i ON i.inv_item_sk = sh.ws_bill_customer_sk
JOIN date_dim d ON d.d_date_sk = (SELECT MIN(ws_sold_date_sk) FROM web_sales WHERE ws_bill_customer_sk = sh.ws_bill_customer_sk)
WHERE sh.profit_rank <= 10
GROUP BY s.ws_bill_customer_sk, customer_name, sh.total_profit, sh.total_orders, i.ib_income_band_sk, d.d_year
ORDER BY accumulated_profit DESC
LIMIT 20;
