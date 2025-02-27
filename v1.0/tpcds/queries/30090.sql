
WITH RECURSIVE Address_Hierarchy AS (
    SELECT ca_address_sk, ca_address_id, ca_street_name, ca_city, ca_state, 1 AS level
    FROM customer_address
    WHERE ca_state = 'CA'
    UNION ALL
    SELECT ch.ca_address_sk, ch.ca_address_id, ch.ca_street_name, ch.ca_city, ch.ca_state, ah.level + 1
    FROM customer_address ch
    JOIN Address_Hierarchy ah ON ch.ca_city = ah.ca_city AND ch.ca_state = ah.ca_state
    WHERE ah.level < 5
),
Aggregate_Sales AS (
    SELECT c.c_customer_sk, SUM(ws.ws_net_paid_inc_tax) AS total_sales, COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY c.c_customer_sk
),
Demographic_Analysis AS (
    SELECT cd.cd_gender, AVG(hd.hd_dep_count) AS avg_dependent_count, COUNT(cd.cd_demo_sk) AS demo_count
    FROM household_demographics hd
    JOIN customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
),
Sales_Comparison AS (
    SELECT a.ca_state, d.cd_gender, SUM(as_sales.total_sales) AS total_sales, COUNT(as_sales.order_count) AS total_orders
    FROM Address_Hierarchy a
    LEFT JOIN Aggregate_Sales as_sales ON as_sales.c_customer_sk IN (
        SELECT DISTINCT c.c_customer_sk FROM customer c WHERE c.c_current_addr_sk = a.ca_address_sk
    )
    LEFT JOIN Demographic_Analysis d ON TRUE
    GROUP BY a.ca_state, d.cd_gender
)
SELECT DISTINCT sc.ca_state, da.cd_gender, 
    COALESCE(sc.total_sales, 0) AS total_sales,
    COALESCE(sc.total_orders, 0) AS total_orders
FROM Sales_Comparison sc
FULL OUTER JOIN Demographic_Analysis da ON sc.cd_gender = da.cd_gender
ORDER BY sc.ca_state, da.cd_gender;
