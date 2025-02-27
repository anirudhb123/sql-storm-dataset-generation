
WITH RECURSIVE sales_data AS (
    SELECT ws_item_sk, 
           ws_order_number, 
           ws_sales_price, 
           ws_quantity, 
           ws_net_profit, 
           1 AS level
    FROM web_sales 
    WHERE ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    UNION ALL
    SELECT ws.ws_item_sk, 
           ws.ws_order_number, 
           ws.ws_sales_price, 
           ws.ws_quantity, 
           ws.ws_net_profit,
           sd.level + 1
    FROM web_sales ws
    JOIN sales_data sd ON ws.ws_order_number = sd.ws_order_number 
    WHERE sd.level < 5
),
customer_sales AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           SUM(sd.ws_net_profit) AS total_net_profit
    FROM customer c
    JOIN sales_data sd ON c.c_customer_sk = sd.ws_item_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
address_details AS (
    SELECT ca.ca_address_sk, 
           ca.ca_city, 
           ca.ca_state, 
           COUNT(DISTINCT cs.c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_sales cs ON c.c_customer_sk = cs.c_customer_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT ad.ca_city, 
       ad.ca_state, 
       ad.customer_count, 
       COALESCE(SUM(cs.total_net_profit), 0) AS total_profit
FROM address_details ad
LEFT JOIN customer_sales cs ON ad.customer_count > 0
GROUP BY ad.ca_city, ad.ca_state, ad.customer_count
HAVING total_profit > (SELECT AVG(total_net_profit) FROM customer_sales)
ORDER BY ad.ca_city, ad.ca_state;
