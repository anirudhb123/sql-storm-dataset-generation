
WITH RECURSIVE AddressCTE AS (
    SELECT ca_address_sk, ca_city, ca_state, 1 AS level
    FROM customer_address
    WHERE ca_state = 'CA'
    
    UNION ALL
    
    SELECT ca_address_sk, ca_city, ca_state, level + 1
    FROM customer_address
    JOIN AddressCTE ON customer_address.ca_address_sk = AddressCTE.ca_address_sk
    WHERE level < 3
),
PriceAdjustment AS (
    SELECT 
        i_item_sk,
        i_item_id,
        CASE 
            WHEN i_current_price > 100 THEN i_current_price * 0.9
            ELSE i_current_price * 1.05 
        END AS adjusted_price
    FROM item
),
SalesData AS (
    SELECT 
        s_store_sk,
        ss_sales_price AS total_sales,
        SUM(ss_quantity) AS total_quantity,
        AVG(ws_net_paid) OVER (PARTITION BY ws_web_page_sk) AS avg_web_price
    FROM store_sales 
    LEFT JOIN web_sales ON store_sales.ss_item_sk = web_sales.ws_item_sk
    GROUP BY s_store_sk, ss_sales_price
)
SELECT 
    a.ca_city,
    a.ca_state,
    SUM(sd.total_sales) AS total_sales_amount,
    COUNT(DISTINCT sd.s_store_sk) AS store_count,
    MAX(pa.adjusted_price) AS max_adjusted_price
FROM AddressCTE a
JOIN SalesData sd ON a.ca_address_sk = sd.s_store_sk
JOIN PriceAdjustment pa ON pa.i_item_sk = sd.s_store_sk
WHERE 
    sd.total_quantity > 5 
    AND (sd.total_sales IS NOT NULL OR a.ca_city IS NOT NULL)
GROUP BY a.ca_city, a.ca_state
HAVING COUNT(*) > 1
ORDER BY total_sales_amount DESC
LIMIT 10;
