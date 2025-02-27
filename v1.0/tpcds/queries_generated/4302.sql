
WITH RankedSales AS (
    SELECT ws_item_sk, 
           ws_sales_price, 
           ws_quantity,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rnk,
           SUM(ws_ext_sales_price) OVER (PARTITION BY ws_item_sk) AS total_sales
    FROM web_sales
),
TopSales AS (
    SELECT rs.ws_item_sk, 
           rs.ws_sales_price, 
           rs.ws_quantity,
           rs.total_sales
    FROM RankedSales rs
    WHERE rs.rnk = 1
),
CustomerDemographics AS (
    SELECT cd_demo_sk, 
           cd_gender, 
           cd_income_band_sk,
           COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd_demo_sk, cd_gender, cd_income_band_sk
)
SELECT ca.ca_city, 
       ca.ca_state, 
       cd.cd_gender,
       SUM(ts.ws_quantity) AS total_quantity,
       AVG(ts.ws_sales_price) AS avg_sales_price,
       MAX(ts.total_sales) AS max_sales_per_item
FROM customer_address ca
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN TopSales ts ON c.c_customer_sk = ts.ws_item_sk
JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE ca.ca_country = 'USA'
GROUP BY ca.ca_city, ca.ca_state, cd.cd_gender
HAVING COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY total_quantity DESC, avg_sales_price DESC;
