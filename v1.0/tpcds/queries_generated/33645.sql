
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk,
           0 AS level
    FROM customer
    WHERE c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer)
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE ch.level < 5
),
SalesData AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_paid) AS total_sales
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
TopItems AS (
    SELECT i.i_item_sk, i.i_item_desc, sd.total_quantity, sd.total_sales,
           RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM item i
    JOIN SalesData sd ON i.i_item_sk = sd.ws_item_sk
    WHERE sd.total_sales > 0
),
CustomerStats AS (
    SELECT 
        cd.cd_gender,
        SUM(CASE WHEN sd.total_sales IS NULL THEN 0 ELSE sd.total_sales END) AS gender_sales,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN TopItems sd ON c.c_current_addr_sk = sd.i_item_sk
    GROUP BY cd.cd_gender
)
SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name,
       cs.gender_sales, cs.customer_count,
       COALESCE(cs.gender_sales / NULLIF(cs.customer_count, 0), 0) AS avg_sales_per_customer
FROM CustomerHierarchy ch
LEFT JOIN CustomerStats cs ON ch.c_customer_sk = cs.c_customer_sk
WHERE cs.gender_sales > 1000
ORDER BY avg_sales_per_customer DESC
LIMIT 10;
