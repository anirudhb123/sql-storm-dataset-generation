
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        CASE 
            WHEN ws.ws_sales_price IS NULL THEN 'Price Unknown'
            ELSE CAST(ws.ws_sales_price AS VARCHAR(20))
        END AS price_string
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
    UNION ALL
    SELECT 
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sales_price,
        cs.cs_quantity,
        RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_sales_price DESC) AS price_rank,
        CASE 
            WHEN cs.cs_sales_price IS NULL THEN 'Price Unknown'
            ELSE CAST(cs.cs_sales_price AS VARCHAR(20))
        END AS price_string
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_ship_date_sk IS NOT NULL
),
SalesSummary AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity,
        AVG(rs.ws_sales_price) AS avg_sales_price,
        STRING_AGG(rs.price_string, ', ') AS price_strings
    FROM 
        RankedSales rs
    WHERE 
        rs.price_rank = 1
    GROUP BY 
        rs.ws_order_number, rs.ws_item_sk
),
SalesAnalysis AS (
    SELECT 
        ss.*,
        CASE 
            WHEN ss.total_quantity > 100 THEN 'High Volume'
            WHEN ss.total_quantity BETWEEN 50 AND 100 THEN 'Medium Volume'
            ELSE 'Low Volume'
        END AS volume_category
    FROM 
        SalesSummary ss
)
SELECT 
    da.d_date,
    sa.ws_order_number,
    sa.ws_item_sk,
    sa.total_quantity,
    sa.avg_sales_price,
    sa.volume_category,
    COALESCE(ca.ca_city, 'Unknown City') AS shipping_city
FROM 
    date_dim da
LEFT JOIN 
    SalesAnalysis sa ON da.d_date_sk = sa.ws_order_number
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = sa.ws_item_sk
WHERE 
    da.d_date BETWEEN '2023-01-01' AND '2023-12-31'
    AND (sa.total_quantity IS NULL OR sa.total_quantity < 50);
