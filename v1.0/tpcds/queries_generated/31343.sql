
WITH RECURSIVE TopCustomers AS (
    SELECT c_customer_sk, 
           SUM(ws_ext_sales_price) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2455588 -- assuming these date SKs represent a meaningful date range
    GROUP BY c_customer_sk
    ORDER BY total_spent DESC
    LIMIT 10
),
CustomerDetails AS (
    SELECT c.c_customer_id, 
           c.c_first_name, 
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           ca.ca_city,
           ca.ca_state,
           RANK() OVER (PARTITION BY ca.ca_state ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS state_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2455588
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, ca.ca_city, ca.ca_state
),
TopStateCustomers AS (
    SELECT cd.c_customer_id,
           cd.c_first_name,
           cd.c_last_name,
           cd.ca_city,
           cd.ca_state
    FROM CustomerDetails cd
    JOIN TopCustomers tc ON cd.c_customer_id = tc.c_customer_sk
    WHERE cd.state_rank <= 5
)
SELECT tsc.c_first_name,
       tsc.c_last_name,
       tsc.ca_city,
       tsc.ca_state,
       COALESCE(SUM(ws.ws_net_profit), 0) AS net_profit
FROM TopStateCustomers tsc
LEFT JOIN web_sales ws ON tsc.c_customer_id = ws.ws_ship_customer_sk
GROUP BY tsc.c_first_name, tsc.c_last_name, tsc.ca_city, tsc.ca_state
HAVING net_profit > 1000 
ORDER BY net_profit DESC
LIMIT 20;
