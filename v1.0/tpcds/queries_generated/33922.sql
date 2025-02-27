
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_street_name, ca_city, ca_state, ca_zip,
           1 AS level
    FROM customer_address
    WHERE ca_state = 'NY'
    
    UNION ALL
    
    SELECT ca_address_sk, ca_street_name, ca_city, ca_state, ca_zip,
           level + 1
    FROM customer_address
    JOIN AddressHierarchy ON customer_address.ca_city = AddressHierarchy.ca_city
    WHERE customer_address.ca_state = 'CA'
),
SalesStats AS (
    SELECT ws.web_site_sk, COUNT(ws.ws_order_number) AS total_sales, SUM(ws.ws_net_paid) AS total_revenue
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2022
    GROUP BY ws.web_site_sk
),
CustomerDemographics AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, 
           COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_demographics cd
    LEFT JOIN customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
StoreSalesRank AS (
    SELECT ss_store_sk, RANK() OVER (ORDER BY SUM(ss_net_paid) DESC) AS store_rank
    FROM store_sales
    GROUP BY ss_store_sk
    HAVING SUM(ss_net_paid) > 50000
)
SELECT ah.ca_street_name, ah.ca_city, ah.ca_state, ah.ca_zip,
       cs.cd_gender, cs.cd_marital_status, cs.customer_count,
       ss.total_sales, ss.total_revenue
FROM AddressHierarchy ah
JOIN CustomerDemographics cs ON cs.customer_count > 10
LEFT JOIN SalesStats ss ON ss.web_site_sk IN (
    SELECT web_site_sk
    FROM store_sales ss
    JOIN StoreSalesRank sr ON ss.ss_store_sk = sr.ss_store_sk
    WHERE sr.store_rank <= 5
)
WHERE ah.level <= 2
AND (cs.cd_marital_status = 'M' OR cs.cd_gender = 'F')
ORDER BY ah.ca_city, ss.total_revenue DESC;
