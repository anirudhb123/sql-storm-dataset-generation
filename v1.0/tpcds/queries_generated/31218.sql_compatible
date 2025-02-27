
WITH RECURSIVE RecursiveSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ws_sold_date_sk,
        1 AS level 
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk, ws_sold_date_sk
    UNION ALL
    SELECT 
        cs_item_sk, 
        SUM(cs_quantity) + r.total_quantity,
        SUM(cs_ext_sales_price) + r.total_sales,
        cs_sold_date_sk,
        level + 1
    FROM 
        catalog_sales cs
    JOIN 
        RecursiveSales r ON cs.cs_ship_date_sk = r.ws_sold_date_sk
    GROUP BY 
        cs_item_sk, cs_sold_date_sk, level
), RankedSales AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_sales,
        d.d_year,
        ROW_NUMBER() OVER (PARTITION BY r.ws_item_sk ORDER BY r.total_sales DESC) AS rank
    FROM 
        RecursiveSales r
    JOIN 
        date_dim d ON r.ws_sold_date_sk = d.d_date_sk
)
SELECT 
    ws_item_sk, 
    SUM(total_quantity) AS total_qty,
    AVG(total_sales) AS avg_sales,
    COUNT(CASE WHEN rank <= 10 THEN 1 END) AS top_rank_count
FROM 
    RankedSales
GROUP BY 
    ws_item_sk
HAVING 
    SUM(total_quantity) > 1000
ORDER BY 
    avg_sales DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
