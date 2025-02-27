
WITH RankedSales AS (
    SELECT 
        ss.store_sk,
        ss_item_sk,
        SUM(ss_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ss.store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales ss
    WHERE 
        ss_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    GROUP BY 
        ss.store_sk, ss_item_sk
),
CustomerReturns AS (
    SELECT 
        sr.store_sk,
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns sr
    JOIN 
        RankedSales rs ON sr.store_sk = rs.store_sk AND sr_item_sk = rs.ss_item_sk
    GROUP BY 
        sr.store_sk, sr_item_sk
)
SELECT 
    s.s_store_name,
    item.i_item_desc,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(cr.total_returns, 0) AS total_returns,
    (COALESCE(rs.total_sales, 0) - COALESCE(cr.total_returns, 0)) AS net_sales,
    CASE 
        WHEN (COALESCE(rs.total_sales, 0) - COALESCE(cr.total_returns, 0)) > 5000 THEN 'High Performer'
        WHEN (COALESCE(rs.total_sales, 0) - COALESCE(cr.total_returns, 0)) > 1000 THEN 'Mid Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    store s
LEFT JOIN 
    RankedSales rs ON s.s_store_sk = rs.store_sk
LEFT JOIN 
    CustomerReturns cr ON s.s_store_sk = cr.store_sk AND rs.ss_item_sk = cr.ss_item_sk
JOIN 
    item ON rs.ss_item_sk = item.i_item_sk
WHERE 
    rs.sales_rank = 1 OR rs.sales_rank IS NULL 
ORDER BY 
    s.s_store_name, net_sales DESC;
