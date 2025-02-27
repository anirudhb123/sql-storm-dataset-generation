
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_sales,
        i.i_item_desc,
        COALESCE(p.p_promo_name, 'No Promotion') AS promo_name,
        ROW_NUMBER() OVER (PARTITION BY rs.sales_rank ORDER BY rs.total_sales DESC) AS rank_within_promo
    FROM 
        RankedSales AS rs
    LEFT JOIN 
        item AS i ON rs.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        promotion AS p ON i.i_item_sk = p.p_item_sk AND p.p_discount_active = 'Y'
    WHERE 
        rs.sales_rank <= 5
)
SELECT 
    ta.ws_item_sk,
    ta.total_sales,
    ta.i_item_desc,
    ta.promo_name,
    CASE 
        WHEN ta.rank_within_promo <= 3 THEN 'Top Performer'
        WHEN ta.total_sales IS NULL OR ta.total_sales <= 0 THEN 'No Sales'
        ELSE 'Standard'
    END AS sales_category
FROM 
    TopSales AS ta
JOIN 
    (SELECT 
        ws_item_sk,
        COUNT(*) AS returns_count
     FROM 
        web_returns
     GROUP BY 
        ws_item_sk) AS wr ON ta.ws_item_sk = wr.ws_item_sk
WHERE 
    (wr.returns_count > 0 AND ta.total_sales < 100) 
    OR (wr.returns_count = 0 AND ta.total_sales > 100)
ORDER BY 
    ta.total_sales DESC
LIMIT 20 OFFSET 0;
