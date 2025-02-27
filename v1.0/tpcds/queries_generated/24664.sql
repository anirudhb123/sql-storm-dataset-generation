
WITH RECURSIVE SalesHistory AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sold_date_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    WHERE ws_quantity > 0
    UNION ALL
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_sold_date_sk,
        cs_quantity,
        cs_sales_price,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_sold_date_sk DESC) AS rn
    FROM catalog_sales
    WHERE cs_quantity > 0
)
, AddressSales AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_address_sk,
        SUM(CASE WHEN sh.ws_quantity IS NOT NULL OR sc.cs_quantity IS NOT NULL THEN 1 ELSE 0 END) AS total_sales,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN SalesHistory sh ON sh.ws_item_sk = c.c_current_hdemo_sk
    LEFT JOIN SalesHistory sc ON sc.ws_item_sk = c.c_current_cdemo_sk
    GROUP BY c.c_customer_sk, ca.ca_address_sk
)
SELECT 
    a.ca_country,
    SUM(a.total_sales) AS total_sales_by_country,
    COUNT(a.unique_customers) AS unique_customer_count,
    CASE 
        WHEN SUM(a.total_sales) IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status,
    MAX(COALESCE(a.total_sales, 0)) OVER (PARTITION BY a.ca_country) AS max_sales_per_country
FROM AddressSales a
GROUP BY a.ca_country
HAVING SUM(a.total_sales) > (
    SELECT AVG(total_sales) FROM AddressSales b WHERE a.ca_country = b.ca_country
)
ORDER BY total_sales_by_country DESC
LIMIT 10;
