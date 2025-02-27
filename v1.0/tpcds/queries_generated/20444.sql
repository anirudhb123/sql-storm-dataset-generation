
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, 1 AS level
    FROM customer_address
    WHERE ca_country IS NOT NULL AND ca_city IS NOT NULL
    UNION ALL
    SELECT ca_address_sk, ca.city, ca.state, ah.level + 1
    FROM AddressHierarchy ah
    JOIN customer_address ca ON ca.ca_address_sk = ah.ca_address_sk
    WHERE ah.level < 5 AND ca.ca_state != 'XX'
), 
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.ws_item_sk
),
ReturnData AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
),
ItemStatistics AS (
    SELECT 
        i.i_item_sk,
        COALESCE(sd.total_quantity, 0) AS total_sold,
        COALESCE(rd.total_return_quantity, 0) AS total_returned,
        (COALESCE(sd.total_sales_price, 0) - COALESCE(rd.total_return_amount, 0)) AS net_sales
    FROM item i
    LEFT JOIN SalesData sd ON i.i_item_sk = sd.ws_item_sk
    LEFT JOIN ReturnData rd ON i.i_item_sk = rd.cr_item_sk
)
SELECT 
    ah.ca_city,
    ah.ca_state,
    i.i_item_id,
    is.total_sold,
    is.total_returned,
    is.net_sales,
    ROW_NUMBER() OVER (PARTITION BY ah.ca_city ORDER BY is.net_sales DESC) AS rank
FROM AddressHierarchy ah
JOIN Customer c ON c.c_current_addr_sk = ah.ca_address_sk
JOIN ItemStatistics is ON is.i_item_sk = c.c_customer_sk
WHERE 
    ah.level BETWEEN 1 AND 3 AND 
    (is.net_sales > (SELECT AVG(net_sales) FROM ItemStatistics) OR 
    EXISTS (SELECT 1 FROM store s WHERE s.s_city = ah.ca_city AND s.s_state = ah.ca_state))
ORDER BY ah.ca_city, rank;
