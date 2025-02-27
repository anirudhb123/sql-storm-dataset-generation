
WITH RECURSIVE SalesData AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_sales_price, 1 AS level
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    
    UNION ALL
    
    SELECT ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_quantity, ws.ws_sales_price, sd.level + 1
    FROM web_sales ws
    JOIN SalesData sd ON ws.ws_sold_date_sk = sd.ws_sold_date_sk - 1 AND ws.ws_item_sk = sd.ws_item_sk
)
SELECT 
    ca_state,
    SUM(CASE WHEN cd_gender = 'F' THEN ws_quantity ELSE 0 END) AS total_female_sales,
    SUM(CASE WHEN cd_gender = 'M' THEN ws_quantity ELSE 0 END) AS total_male_sales,
    AVG(ws_sales_price) AS average_sales_price,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    MAX(ws_sales_price) AS max_sales_price,
    MIN(ws_sales_price) AS min_sales_price,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY SUM(ws_quantity) DESC) AS state_rank
FROM SalesData sd
JOIN customer c ON c.c_customer_sk = sd.ws_bill_customer_sk
JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
JOIN customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN item i ON i.i_item_sk = sd.ws_item_sk
WHERE ws_sales_price IS NOT NULL
AND (ws_quantity > 0 OR ws_quantity IS NULL)
AND (ca_state IS NOT NULL AND ca_state <> '')
GROUP BY ca_state
HAVING SUM(ws_quantity) > 100
ORDER BY state_rank
LIMIT 10;
