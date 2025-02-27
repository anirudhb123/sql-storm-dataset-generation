
WITH RECURSIVE AddressCTE AS (
    SELECT ca_address_sk, ca_city, ca_state
    FROM customer_address
    WHERE ca_city IS NOT NULL

    UNION ALL

    SELECT a.ca_address_sk, a.ca_city, a.ca_state
    FROM customer_address a
    JOIN AddressCTE b ON a.ca_state = b.ca_state AND a.ca_city <> b.ca_city
    WHERE a.ca_city IS NOT NULL
),

SalesData AS (
    SELECT 
        ws.ws_order_number, 
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_item_sk) AS total_items,
        DENSE_RANK() OVER (PARTITION BY ws.ws_bill_cdemo_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY ws.ws_order_number, ws.ws_bill_cdemo_sk
)

SELECT 
    a.ca_city,
    a.ca_state,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_items, 0) AS total_items,
    CASE 
        WHEN sd.sales_rank = 1 THEN 'Top Sales'
        WHEN sd.sales_rank IS NULL THEN 'No Sales'
        ELSE 'Regular Sales'
    END AS sales_category
FROM AddressCTE a
LEFT JOIN SalesData sd ON a.ca_city = (
    SELECT DISTINCT assumed_city 
    FROM customer_address ca 
    WHERE ca.ca_address_sk = c.c_current_addr_sk)
LEFT JOIN customer c ON c.c_current_addr_sk = a.ca_address_sk
WHERE a.ca_state = 'CA'
ORDER BY total_sales DESC, a.ca_city ASC
LIMIT 10;

