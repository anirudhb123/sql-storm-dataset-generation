
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL 
        AND ws.ws_sales_price > 0
),
AggregateSales AS (
    SELECT 
        ir.i_item_id,
        SUM(r.ws_sales_price * r.ws_quantity) AS TotalSales,
        AVG(r.ws_sales_price) AS AveragePrice,
        MIN(r.ws_sales_price) AS MinimumPrice,
        MAX(r.ws_sales_price) AS MaximumPrice,
        COUNT(r.ws_order_number) AS OrderCount
    FROM 
        RankedSales r
    JOIN 
        item ir ON r.ws_item_sk = ir.i_item_sk
    WHERE 
        r.SalesRank <= 10
    GROUP BY 
        ir.i_item_id
),
TopItems AS (
    SELECT 
        a.i_item_id,
        a.TotalSales,
        a.AveragePrice,
        a.MinimumPrice,
        a.MaximumPrice,
        DENSE_RANK() OVER (ORDER BY a.TotalSales DESC) AS ItemRank
    FROM 
        AggregateSales a
)
SELECT 
    ti.i_item_id,
    ti.TotalSales,
    ti.AveragePrice,
    ti.MinimumPrice,
    ti.MaximumPrice,
    ca.ca_city,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS UniqueCustomers
FROM 
    TopItems ti
LEFT JOIN 
    web_sales ws ON ti.i_item_id = ws.ws_item_sk
LEFT JOIN 
    customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ti.ItemRank <= 5
GROUP BY 
    ti.i_item_id, ti.TotalSales, ti.AveragePrice, ti.MinimumPrice, ti.MaximumPrice, ca.ca_city
ORDER BY 
    ti.TotalSales DESC
LIMIT 100;
