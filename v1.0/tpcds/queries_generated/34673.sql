
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_address_id, ca_street_name, ca_city, ca_state, ca_zip, 1 AS level
    FROM customer_address
    WHERE ca_state = 'NY'
    UNION ALL
    SELECT ca.ca_address_sk, ca.ca_address_id, ca.ca_street_name, ca.ca_city, ca.ca_state, ca.ca_zip, ah.level + 1
    FROM customer_address ca
    JOIN AddressHierarchy ah ON ca.ca_zip = ah.ca_zip AND ca.ca_address_sk != ah.ca_address_sk
    WHERE ah.level < 3
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_net_profit) AS total_profit,
        MAX(cs.cs_sold_date_sk) AS last_order_date
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_sk
),
IncomeDistribution AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(c.c_customer_sk) AS customer_count
    FROM household_demographics hd
    JOIN customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY hd.hd_income_band_sk
),
SalesPerformance AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_catalog_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    ah.ca_address_id,
    cs.c_customer_sk,
    cs.total_orders,
    cs.total_profit,
    cs.last_order_date,
    s.total_web_sales,
    s.total_catalog_sales,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM AddressHierarchy ah
JOIN CustomerStats cs ON cs.c_customer_sk = c.c_customer_sk
JOIN IncomeDistribution id ON id.hd_income_band_sk = hd.hd_income_band_sk
JOIN SalesPerformance s ON s.c_customer_sk = cs.c_customer_sk
JOIN income_band ib ON id.hd_income_band_sk = ib.ib_income_band_sk
WHERE cs.total_profit > 0
  AND ah.level = 1
ORDER BY ah.ca_city, cs.total_profit DESC
LIMIT 100;
