
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_quantity) DESC) AS rank_sales
    FROM 
        web_sales ws
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_sk, 
        ws_sold_date_sk, 
        ws_item_sk
), 
FilteredSales AS (
    SELECT 
        rs.web_site_sk,
        SUM(CASE WHEN rs.total_quantity IS NOT NULL THEN rs.total_quantity ELSE 0 END) AS total_quantity_positive,
        SUM(CASE WHEN rs.total_quantity IS NULL THEN 1 ELSE 0 END) AS total_quantity_null,
        DENSE_RANK() OVER (ORDER BY SUM(rs.total_quantity) DESC) AS sales_rank
    FROM 
        RankedSales rs
    GROUP BY 
        rs.web_site_sk
)
SELECT 
    f.web_site_sk,
    f.total_quantity_positive,
    f.total_quantity_null,
    CASE
        WHEN f.total_quantity_positive > 1000 THEN 'High'
        WHEN f.total_quantity_positive BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS quantity_category,
    CASE 
        WHEN EXISTS (SELECT 1 FROM store WHERE s_state = 'CA' AND s_store_sk IN (SELECT cs_ship_mode_sk FROM catalog_sales WHERE cs_item_sk = f.web_site_sk)) 
        THEN 'Shipping to CA'
        ELSE 'Not Shipping to CA'
    END AS shipping_info
FROM 
    FilteredSales f
WHERE 
    f.sales_rank <= 10
ORDER BY 
    f.total_quantity_positive DESC, f.web_site_sk;
