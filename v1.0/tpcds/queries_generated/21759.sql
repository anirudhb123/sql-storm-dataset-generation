
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS SalesRank,
        SUM(ws_sales_price) OVER (PARTITION BY ws_item_sk) AS TotalSales
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL
),
AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS CustomerCount
    FROM customer_address
    JOIN customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
    GROUP BY ca_state
),
TopItems AS (
    SELECT 
        i_item_id,
        i_item_desc,
        COUNT(DISTINCT ws_order_number) AS OrderCount,
        AVG(ws_sales_price) AS AvgSalesPrice
    FROM web_sales
    JOIN item ON web_sales.ws_item_sk = item.i_item_sk
    WHERE ws_sold_date_sk IN (SELECT DISTINCT ws_sold_date_sk FROM web_sales WHERE ws_sold_date_sk IS NOT NULL)
    GROUP BY i_item_id, i_item_desc
    HAVING COUNT(DISTINCT ws_order_number) > 5
)
SELECT 
    ca.ca_state,
    ai.i_item_id,
    ai.i_item_desc,
    ai.OrderCount,
    ai.AvgSalesPrice,
    CASE 
        WHEN ai.AvgSalesPrice = 0 THEN NULL 
        ELSE SUM(CASE WHEN rs.SalesRank = 1 THEN rs.ws_sales_price ELSE 0 END) / COUNT(DISTINCT ai.i_item_id)
    END AS TopItemSalesAverage,
    a.CustomerCount
FROM TopItems ai
LEFT JOIN RankedSales rs ON ai.i_item_sk = rs.ws_item_sk
JOIN AddressStats a ON a.ca_state = 'CA'
GROUP BY ca.ca_state, ai.i_item_id, ai.i_item_desc, a.CustomerCount
HAVING COUNT(DISTINCT ai.OrderCount) >= 3
ORDER BY a.CustomerCount DESC, ai.AvgSalesPrice DESC
LIMIT 10
UNION ALL
SELECT 
    'UNKNOWN' AS ca_state,
    NULL AS i_item_id,
    NULL AS i_item_desc,
    COUNT(DISTINCT ws_order_number) AS OrderCount,
    AVG(ws_sales_price) AS AvgSalesPrice,
    NULL AS TopItemSalesAverage,
    NULL AS CustomerCount
FROM web_sales
WHERE ws_sales_price IS NULL
GROUP BY ws_sold_date_sk
ORDER BY OrderCount DESC
LIMIT 5;
