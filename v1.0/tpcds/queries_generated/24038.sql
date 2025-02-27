
WITH RECURSIVE AddressCTE AS (
    SELECT ca_address_sk, ca_city, ca_state
    FROM customer_address
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT ca_address_sk, ca_city, ca_state
    FROM customer_address a
    JOIN AddressCTE c ON a.ca_city = c.ca_city AND a.ca_state != c.ca_state
),
SalesSummary AS (
    SELECT
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ws_ship_mode_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_ship_mode_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_ship_mode_sk
),
CustomerDemographics AS (
    SELECT cd_demo_sk, cd_gender, cd_marital_status,
           COUNT(c.customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd_demo_sk, cd_gender, cd_marital_status
    HAVING COUNT(c.customer_sk) > 10
)
SELECT
    s.ss_ticket_number,
    ws.ws_web_page_sk,
    ws.ws_ship_mode_sk,
    ss.total_sales,
    addr.ca_city,
    addr.ca_state,
    cd.cd_gender,
    cd.customer_count,
    (SELECT COUNT(*)
     FROM store s
     WHERE s.s_state = addr.ca_state
       AND s.s_zip IS NOT NULL) AS store_count,
    CASE 
        WHEN cd.cd_marital_status = 'M' THEN 'Married'
        WHEN cd.cd_marital_status = 'S' THEN 'Single'
        ELSE 'Other'
    END AS marital_status,
    RANK() OVER (PARTITION BY addr.ca_city ORDER BY total_sales DESC) AS city_sales_rank
FROM store_sales s
JOIN web_sales ws ON s.ss_item_sk = ws.ws_item_sk
LEFT OUTER JOIN AddressCTE addr ON addr.ca_address_sk = s.ss_addr_sk
JOIN SalesSummary ss ON ws.ws_ship_mode_sk = ss.ws_ship_mode_sk
JOIN CustomerDemographics cd ON cd.cd_demo_sk = s.ss_cdemo_sk
WHERE ws.ws_ship_date_sk BETWEEN 2459216 AND 2459276
  AND ss.total_sales IS NOT NULL
  AND addr.ca_city IS NOT NULL
  AND (addr.ca_city LIKE '%ville%' OR addr.ca_state = 'CA')
ORDER BY addr.ca_city, ss.total_sales DESC;
