
WITH RECURSIVE CustomerCTE AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           c_preferred_cust_flag,
           c_birth_year,
           0 AS Level
    FROM customer
    WHERE c_birth_year IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_preferred_cust_flag,
           c.c_birth_year,
           Level + 1
    FROM customer c
    JOIN CustomerCTE cc ON c.c_customer_sk = cc.c_customer_sk
    WHERE cc.Level < 2
),
SalesData AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk 
                                   FROM date_dim
                                   WHERE d_year = 2023)
    GROUP BY ws.ws_item_sk
),
CustomerSales AS (
    SELECT ca.ca_address_id,
           cd.cd_gender,
           cd.cd_marital_status,
           SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
    WHERE c.c_preferred_cust_flag = 'Y'
      AND (cd.cd_marital_status = 'S' OR cd.cd_gender = 'F')
    GROUP BY ca.ca_address_id, cd.cd_gender, cd.cd_marital_status
),
AggregatedSales AS (
    SELECT cs.ca_address_id,
           cs.cd_gender,
           cs.cd_marital_status,
           COALESCE(cs.total_profit, 0) AS total_profit,
           ROW_NUMBER() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_profit DESC) AS profit_rank
    FROM CustomerSales cs
    LEFT JOIN SalesData sd ON cs.total_profit = sd.total_profit
)
SELECT c.first_name,
       c.last_name,
       c_birth_year,
       a.ca_address_id,
       a.total_profit,
       CASE WHEN a.profit_rank <= 10 THEN 'Top 10 Profitable' ELSE 'Others' END AS Profit_Status
FROM CustomerCTE c
JOIN AggregatedSales a ON c.c_customer_sk = a.ca_address_id
WHERE c.c_preferred_cust_flag = 'Y'
  AND (a.total_profit IS NOT NULL OR a.total_profit = 0)
ORDER BY c.c_birth_year DESC, a.total_profit DESC;
