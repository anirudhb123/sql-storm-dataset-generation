
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_sales_price DESC) AS price_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.web_site_id) AS total_quantity
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
), 
FilteredSales AS (
    SELECT 
        rs.web_site_id,
        rs.ws_item_sk,
        rs.ws_sales_price,
        rs.price_rank,
        CASE 
            WHEN rs.total_quantity > 100 THEN 'High Volume'
            WHEN rs.total_quantity IS NULL THEN 'No Sales'
            ELSE 'Regular Volume'
        END AS volume_category
    FROM 
        RankedSales rs
    WHERE 
        rs.price_rank <= 10
), 
SalesSummary AS (
    SELECT 
        ps.web_site_id,
        COUNT(*) AS items_ranked,
        AVG(ps.ws_sales_price) AS avg_sales_price,
        MAX(ps.ws_sales_price) AS max_sales_price,
        MIN(ps.ws_sales_price) AS min_sales_price,
        STRING_AGG(ps.volume_category, ', ') AS volume_distribution
    FROM 
        FilteredSales ps
    GROUP BY 
        ps.web_site_id
)
SELECT 
    s.web_site_id,
    s.items_ranked,
    s.avg_sales_price,
    s.max_sales_price,
    s.min_sales_price,
    s.volume_distribution,
    CASE 
        WHEN s.avg_sales_price > 100.00 THEN 'Premium'
        WHEN s.avg_sales_price IS NULL THEN 'No Data'
        ELSE 'Standard'
    END AS pricing_category,
    NULLIF(s.items_ranked, 0) AS non_zero_item_count -- handling NULL logic
FROM 
    SalesSummary s
LEFT JOIN 
    web_site w ON s.web_site_id = w.web_site_id
WHERE 
    w.web_state IS NOT NULL
ORDER BY 
    s.avg_sales_price DESC 
LIMIT 100;
