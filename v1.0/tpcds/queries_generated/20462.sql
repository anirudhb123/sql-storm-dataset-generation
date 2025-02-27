
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_sales_price,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rn
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL
),
HighValueSales AS (
    SELECT 
        r.ws_item_sk,
        MAX(r.ws_sales_price) AS max_sales_price,
        SUM(r.ws_net_paid) AS total_net_paid
    FROM RankedSales r
    WHERE r.rn <= 10
    GROUP BY r.ws_item_sk
),
CustomerAddressInfo AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE ca.ca_city IS NOT NULL AND ca.ca_state IS NOT NULL
    GROUP BY ca.ca_address_id, ca.ca_city, ca.ca_state, ca.ca_country
)
SELECT 
    c.c_customer_id,
    s.ss_sold_date_sk,
    s.ss_item_sk,
    COALESCE(hi.total_net_paid, 0) AS total_net_paid,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM store_sales s
JOIN customer c ON s.ss_customer_sk = c.c_customer_sk
LEFT JOIN HighValueSales hi ON s.ss_item_sk = hi.ws_item_sk
INNER JOIN CustomerAddressInfo ca ON c.c_current_addr_sk = ca.ca_address_id
WHERE s.ss_sales_price BETWEEN 100 AND 500
  AND (s.ss_quantity > 5 OR hi.total_net_paid IS NOT NULL)
  AND hi.total_net_paid IS NOT NULL
ORDER BY ca.ca_country DESC, hi.max_sales_price DESC
FETCH FIRST 100 ROWS ONLY;
