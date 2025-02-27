
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_sold_date_sk, ws_item_sk
),
Address_Summary AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        COUNT(DISTINCT CASE WHEN cd_gender = 'F' THEN c_customer_sk END) AS female_customers
    FROM customer
    JOIN customer_address ON c_current_addr_sk = ca_address_sk
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY ca_city
),
Ranked_Sales AS (
    SELECT 
        s.ws_item_sk,
        s.total_sales,
        a.ca_city
    FROM Sales_CTE s
    JOIN (
        SELECT 
            ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS SalesRank,
            ws_item_sk,
            SUM(ws_quantity) AS total_qty
        FROM web_sales
        GROUP BY ws_item_sk
    ) AS r ON s.ws_item_sk = r.ws_item_sk
    JOIN customer c ON c.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales ws WHERE ws_item_sk = r.ws_item_sk LIMIT 1)
    JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    WHERE r.SalesRank <= 10
)
SELECT 
    a.ca_city,
    SUM(s.total_sales) AS city_sales,
    a.customer_count,
    a.female_customers,
    (SELECT COUNT(DISTINCT ws_item_sk) FROM web_sales) AS total_items 
FROM Ranked_Sales s
JOIN Address_Summary a ON s.ca_city = a.ca_city
GROUP BY a.ca_city, a.customer_count, a.female_customers;
