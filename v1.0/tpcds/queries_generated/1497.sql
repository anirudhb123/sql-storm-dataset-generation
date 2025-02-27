
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS PriceRank
    FROM web_sales ws
),
TotalSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS TotalQuantity,
        SUM(ws.ws_sales_price) AS TotalRevenue
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
StoreReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS TotalReturns,
        SUM(sr.sr_return_amt_inc_tax) AS TotalReturnAmount
    FROM store_returns sr
    GROUP BY sr.sr_item_sk
)
SELECT 
    ca.ca_city,
    TotalSales.ws_item_sk,
    TotalSales.TotalQuantity,
    TotalSales.TotalRevenue,
    COALESCE(StoreReturns.TotalReturns, 0) AS TotalReturns,
    COALESCE(StoreReturns.TotalReturnAmount, 0) AS TotalReturnAmount,
    (TotalSales.TotalRevenue - COALESCE(StoreReturns.TotalReturnAmount, 0)) AS NetSales,
    (CASE 
        WHEN TotalSales.TotalRevenue > 0 THEN 
            (TotalSales.TotalRevenue - COALESCE(StoreReturns.TotalReturnAmount, 0)) / TotalSales.TotalRevenue * 100 
        ELSE 
            NULL 
    END) AS RefundPercentage,
    COUNT(DISTINCT c.c_customer_id) AS UniqueCustomers,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS CustomerNames
FROM TotalSales
LEFT JOIN StoreReturns ON TotalSales.ws_item_sk = StoreReturns.sr_item_sk
JOIN web_sales ws ON TotalSales.ws_item_sk = ws.ws_item_sk
LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE TotalSales.TotalRevenue > 1000
AND ca.ca_state = 'CA'
GROUP BY ca.ca_city, TotalSales.ws_item_sk, TotalSales.TotalQuantity, TotalSales.TotalRevenue
HAVING SUM(ws.ws_quantity) > 100
ORDER BY NetSales DESC
LIMIT 10;
