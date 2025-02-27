
WITH RECURSIVE customer_cte AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_email_address, c_birth_year,
           ROW_NUMBER() OVER (PARTITION BY c_customer_sk ORDER BY c_birth_month DESC) AS rn
    FROM customer
    WHERE c_birth_year IS NOT NULL
),
recent_sales AS (
    SELECT ws_bill_customer_sk, SUM(ws_net_profit) AS total_profit
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    GROUP BY ws_bill_customer_sk
),
store_sales_summary AS (
    SELECT ss_store_sk, COUNT(ss_ticket_number) AS total_sales, SUM(ss_net_profit) AS total_profit
    FROM store_sales
    GROUP BY ss_store_sk
),
stored_addresses AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country
    FROM customer_address
    WHERE ca_country IS NOT NULL
),
sales_analysis AS (
    SELECT c.first_name, c.last_name, c.email_address, 
           COALESCE(r.total_profit, 0) AS web_total_profit,
           COALESCE(s.total_profit, 0) AS store_total_profit,
           a.ca_city, a.ca_state
    FROM customer_cte c
    LEFT JOIN recent_sales r ON c.c_customer_sk = r.ws_bill_customer_sk
    LEFT JOIN store_sales_summary s ON s.ss_store_sk = (SELECT s_store_sk FROM store WHERE s_manager = c.c_last_name LIMIT 1)
    LEFT JOIN stored_addresses a ON a.ca_address_sk = c.c_current_addr_sk
    WHERE c.rn = 1
)
SELECT city, state, SUM(web_total_profit + store_total_profit) AS total_combined_profit
FROM sales_analysis
WHERE web_total_profit + store_total_profit > 1000
GROUP BY city, state
HAVING COUNT(DISTINCT email_address) > 10
ORDER BY total_combined_profit DESC
LIMIT 5;
