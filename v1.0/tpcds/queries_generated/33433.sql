
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        s.ws_sold_date_sk,
        s.ws_item_sk,
        SUM(s.ws_quantity) + sc.total_quantity,
        SUM(s.ws_ext_sales_price) + sc.total_sales
    FROM 
        web_sales s
    JOIN 
        SalesCTE sc ON s.ws_item_sk = sc.ws_item_sk AND s.ws_sold_date_sk > sc.ws_sold_date_sk
    GROUP BY 
        s.ws_sold_date_sk, s.ws_item_sk
),
RankedSales AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY total_sales DESC) AS rank_sales
    FROM 
        SalesCTE
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(rs.total_quantity, 0) AS total_quantity_sold,
    COALESCE(rs.total_sales, 0) AS total_sales_amount,
    CASE 
        WHEN rs.rank_sales <= 10 THEN 'Top 10'
        ELSE 'Not Top 10'
    END AS sales_rank_category
FROM 
    item i
LEFT JOIN 
    RankedSales rs ON i.i_item_sk = rs.ws_item_sk
WHERE 
    i.i_current_price IS NOT NULL
    AND i.i_rec_start_date <= (SELECT MAX(d_date) FROM date_dim WHERE d_current_year = 'Y')
ORDER BY 
    total_sales_amount DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
