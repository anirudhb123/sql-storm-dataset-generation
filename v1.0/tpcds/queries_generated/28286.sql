
WITH Address_City AS (
    SELECT DISTINCT ca_city, ca_state, LENGTH(ca_street_name) AS street_name_length
    FROM customer_address
), 
Customer_Demographics AS (
    SELECT cd_gender, cd_marital_status, COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd_gender, cd_marital_status
), 
Item_Description AS (
    SELECT i_item_id, CONCAT(i_brand, ' ', i_product_name) AS full_description
    FROM item
),
Sales_With_Description AS (
    SELECT ws.ws_order_number,
           ws.ws_item_sk,
           id.full_description,
           ws.ws_quantity,
           ws.ws_ext_sales_price,
           ws.ws_net_profit
    FROM web_sales ws
    JOIN Item_Description id ON ws.ws_item_sk = id.i_item_sk
),
Total_Sales AS (
    SELECT SUM(ws_ext_sales_price) AS total_sales,
           SUM(ws_net_profit) AS total_profit
    FROM Sales_With_Description
),
City_Stats AS (
    SELECT ac.ca_city AS city,
           ac.ca_state AS state,
           COUNT(DISTINCT ss.ss_customer_sk) AS total_customers,
           MAX(ac.street_name_length) AS max_street_length
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN Address_City ac ON ac.ca_city = ca.ca_city AND ac.ca_state = ca.ca_state
    GROUP BY ac.ca_city, ac.ca_state
)

SELECT cd.cd_gender,
       cd.cd_marital_status,
       cd.customer_count,
       ts.total_sales,
       ts.total_profit,
       cs.city,
       cs.state,
       cs.total_customers,
       cs.max_street_length
FROM Customer_Demographics cd,
     Total_Sales ts,
     City_Stats cs
ORDER BY cd.customer_count DESC, ts.total_sales DESC, cs.total_customers DESC
LIMIT 100;
