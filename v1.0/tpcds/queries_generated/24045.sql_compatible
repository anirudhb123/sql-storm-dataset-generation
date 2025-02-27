
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        SUM(ws.ws_sales_price) OVER (PARTITION BY ws.ws_item_sk) AS total_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0
),
HighestSales AS (
    SELECT 
        rs.ws_item_sk,
        MAX(rs.ws_sales_price) AS max_sales_price,
        MIN(rs.ws_sales_price) AS min_sales_price,
        COUNT(*) AS sales_count
    FROM 
        RankedSales rs
    WHERE 
        rs.price_rank <= 5
    GROUP BY 
        rs.ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        hs.max_sales_price,
        hs.min_sales_price,
        hs.sales_count
    FROM 
        item i
    JOIN 
        HighestSales hs ON i.i_item_sk = hs.ws_item_sk
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS purchase_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    id.i_item_id,
    id.i_item_desc,
    CASE 
        WHEN id.max_sales_price IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status,
    COALESCE(cp.purchase_count, 0) AS unique_customers
FROM 
    ItemDetails id
LEFT JOIN 
    CustomerPurchases cp ON cp.purchase_count > 0
WHERE 
    (id.sales_count > (SELECT AVG(sales_count) FROM HighestSales) OR id.sales_count IS NULL)
ORDER BY 
    id.max_sales_price DESC
LIMIT 10;
