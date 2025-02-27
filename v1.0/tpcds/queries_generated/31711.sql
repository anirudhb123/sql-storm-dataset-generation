
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk

    UNION ALL

    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_sales
    FROM catalog_sales
    GROUP BY cs_sold_date_sk, cs_item_sk
), RankedSales AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        RANK() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_sales DESC) AS rank
    FROM SalesData sd
)
SELECT 
    ca.ca_state, 
    SUM(rs.total_quantity) AS total_quantity_sold,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    AVG(rs.total_sales) AS avg_sales_per_item,
    CASE 
        WHEN SUM(rs.total_sales) IS NULL THEN 'No Sales'
        ELSE CONCAT('$', FORMAT(SUM(rs.total_sales), 2))
    END AS total_sales
FROM RankedSales rs
JOIN customer c ON c.c_customer_sk IN (
    SELECT sr_customer_sk 
    FROM store_returns 
    WHERE sr_return_quantity > (
        SELECT AVG(sr_return_quantity) 
        FROM store_returns
    )
)
JOIN customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN item i ON i.i_item_sk = rs.ws_item_sk
WHERE rs.rank = 1
AND ca.ca_state IS NOT NULL 
GROUP BY ca.ca_state
HAVING total_quantity_sold > 100
ORDER BY total_quantity_sold DESC;
