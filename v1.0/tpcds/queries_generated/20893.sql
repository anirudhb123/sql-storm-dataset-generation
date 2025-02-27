
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        ws.ws_sales_price, 
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
AggregateSales AS (
    SELECT 
        rs.ws_item_sk,
        COUNT(*) AS total_sales,
        SUM(rs.ws_sales_price) AS total_revenue,
        AVG(rs.ws_sales_price) AS avg_price
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 5
    GROUP BY 
        rs.ws_item_sk
),
SalesAnalysis AS (
    SELECT 
        i.i_item_id,
        COALESCE(as.total_sales, 0) AS total_sales,
        COALESCE(as.total_revenue, 0) AS total_revenue,
        COALESCE(as.avg_price, 0) AS avg_price,
        CASE 
            WHEN COALESCE(as.total_sales, 0) = 0 THEN 'No Sales'
            WHEN COALESCE(as.total_revenue, 0) < 100 THEN 'Low Revenue'
            ELSE 'Good Sales'
        END AS sales_category
    FROM 
        item i
    LEFT JOIN 
        AggregateSales as ON i.i_item_sk = as.ws_item_sk
),
TopItems AS (
    SELECT 
        sia.i_item_id,
        sia.total_sales,
        sia.total_revenue,
        sia.avg_price,
        ROW_NUMBER() OVER (ORDER BY sia.total_revenue DESC) AS rank
    FROM 
        SalesAnalysis sia
)
SELECT 
    ti.i_item_id,
    ti.total_sales,
    ti.total_revenue,
    ti.avg_price,
    CASE 
        WHEN ti.rank <= 10 THEN 'Top Seller'
        WHEN ti.rank <= 20 THEN 'High Potential'
        ELSE 'Regular Item'
    END AS item_rank_category
FROM 
    TopItems ti
WHERE 
    ti.total_sales IS NOT NULL
    AND ti.total_sales > 0
    OR ti.total_revenue IS NOT NULL
ORDER BY 
    ti.total_revenue DESC, 
    ti.i_item_id
LIMIT 50;
