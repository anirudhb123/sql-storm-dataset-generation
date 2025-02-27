
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_zip, 0 AS level
    FROM customer_address
    WHERE ca_city IS NOT NULL
    UNION ALL
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_zip, ah.level + 1
    FROM customer_address ca
    JOIN AddressHierarchy ah ON ca.ca_zip = ah.ca_zip AND ca.ca_state = ah.ca_state
    WHERE ah.level < 3
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 10000 AND 20000
    GROUP BY ws.ws_item_sk
),
TopSales AS (
    SELECT ws_item_sk, total_sales
    FROM SalesData
    WHERE sales_rank = 1
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        MAX(cd.cd_purchase_estimate) AS max_estimate,
        MIN(cd.cd_credit_rating) AS min_rating,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender
),
AggregatedInfo AS (
    SELECT 
        ah.ca_city,
        cd.cd_gender,
        SUM(ts.total_sales) AS total_sales_by_city,
        COUNT(DISTINCT ts.ws_item_sk) AS items_sold
    FROM AddressHierarchy ah
    JOIN CustomerDemographics cd ON cd.customer_count > 0
    LEFT JOIN TopSales ts ON ts.ws_item_sk IN (
        SELECT ss_item_sk FROM store_sales 
        WHERE ss_sold_date_sk BETWEEN 10000 AND 20000
    )
    GROUP BY ah.ca_city, cd.cd_gender
)
SELECT 
    a.ca_city,
    a.ca_state,
    CASE 
        WHEN a.ca_zip IS NOT NULL THEN 'In State'
        ELSE 'Out of State'
    END AS state_status,
    ai.total_sales_by_city,
    COALESCE(ai.items_sold, 0) AS total_items_sold,
    RANK() OVER (ORDER BY ai.total_sales_by_city DESC) AS city_rank
FROM AddressHierarchy a
LEFT JOIN AggregatedInfo ai ON a.ca_city = ai.ca_city
WHERE EXISTS (
    SELECT 1
    FROM store s
    WHERE s.s_state = a.ca_state AND s.s_closed_date_sk IS NULL
)
ORDER BY city_rank, a.ca_city;
