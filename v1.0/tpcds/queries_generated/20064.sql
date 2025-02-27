
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 0 AS hierarchy_level
    FROM customer_address
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT ca_address_sk, ca_city, ca_state, ca_country, hierarchy_level + 1
    FROM customer_address ca
    JOIN AddressHierarchy ah ON ca.ca_state = ah.ca_state AND ca.ca_city <> ah.ca_city
    WHERE hierarchy_level < 2
),
CustomerMetrics AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           d.d_year,
           COUNT(DISTINCT ws_order_number) AS total_orders,
           SUM(ws_net_profit) AS total_net_profit,
           AVG(ws_sales_price) AS avg_sales_price
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
),
SalesSummary AS (
    SELECT cd.cd_demo_sk, 
           SUM(ws.ws_sales_price) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer_demographics cd
    LEFT JOIN web_sales ws ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
    GROUP BY cd.cd_demo_sk
),
EdgeCases AS (
    SELECT ca.ca_city, 
           ca.ca_state, 
           SUM(COALESCE(ws.ws_net_profit, 0)) AS total_profit,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer_address ca
    LEFT JOIN web_sales ws ON ca.ca_address_sk = ws.ws_ship_addr_sk
    GROUP BY ca.ca_city, ca.ca_state
    HAVING COUNT(DISTINCT ws.ws_item_sk) > 0 OR SUM(ws.ws_net_profit) IS NULL
)
SELECT a.hierarchy_level, 
       cm.c_first_name, 
       cm.c_last_name, 
       cm.total_orders,
       cm.total_net_profit,
       cm.avg_sales_price,
       ss.total_sales,
       ec.total_profit,
       ec.total_orders
FROM AddressHierarchy a
JOIN CustomerMetrics cm ON a.ca_city = cm.c_first_name  -- assuming a bizarre relationship
LEFT JOIN SalesSummary ss ON ss.cd_demo_sk = cm.c_customer_sk
FULL OUTER JOIN EdgeCases ec ON ec.ca_city = a.ca_city AND ec.ca_state = a.ca_state
WHERE (cm.total_orders > COALESCE(ss.order_count, 0) OR ec.total_profit IS NULL)
ORDER BY cm.total_net_profit DESC, a.hierarchy_level, ec.total_orders DESC
LIMIT 100 OFFSET 10;
