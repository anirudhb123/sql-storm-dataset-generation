
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_address_id, ca_city, ca_state, 0 AS level
    FROM customer_address
    WHERE ca_city IS NOT NULL AND ca_state IS NOT NULL
    UNION ALL
    SELECT ca.ca_address_sk, ca.ca_address_id, ca.ca_city, ca.ca_state, ah.level + 1
    FROM customer_address ca 
    JOIN AddressHierarchy ah ON ca.ca_state = ah.ca_state AND ca.ca_city <> ah.ca_city
    WHERE ah.level < 5
),
CustomerDemographics AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, 
           COUNT(DISTINCT c.c_customer_id) AS customer_count, 
           SUM(COALESCE(c.c_birth_year, 0)) AS total_birth_year
    FROM customer c 
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
FilteredSales AS (
    SELECT ws.web_site_sk, SUM(ws.ws_quantity) AS total_sales, 
           SUM(ws.ws_net_profit) AS total_profit, 
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    WHERE ws.ws_sales_price > 
          (SELECT AVG(ws_sub.ws_sales_price) 
           FROM web_sales ws_sub
           WHERE ws_sub.ws_ship_date_sk IS NOT NULL)
    GROUP BY ws.web_site_sk
)
SELECT ah.ca_city, ah.ca_state, 
       cd.cd_gender, cd.cd_marital_status, 
       fs.total_sales, fs.total_profit, fs.order_count,
       RANK() OVER (PARTITION BY ah.ca_state ORDER BY fs.total_profit DESC) AS profit_rank
FROM AddressHierarchy ah
JOIN CustomerDemographics cd ON cd.customer_count > 1
LEFT JOIN FilteredSales fs ON fs.web_site_sk = ah.ca_address_sk
WHERE (fs.total_sales IS NULL OR fs.total_sales > 100) 
AND (ah.level = 2 OR ah.level = 3)
ORDER BY ah.ca_state, profit_rank
FETCH FIRST 10 ROWS ONLY;
