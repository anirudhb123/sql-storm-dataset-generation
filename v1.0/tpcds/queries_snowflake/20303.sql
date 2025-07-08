WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS rnk
    FROM 
        web_sales
    WHERE 
        ws_net_paid IS NOT NULL
),

FilteredSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        rs.ws_net_paid,
        (SELECT COUNT(1) 
         FROM web_sales 
         WHERE ws_item_sk = rs.ws_item_sk 
           AND ws_net_paid > rs.ws_net_paid) AS higher_sales_count
    FROM 
        RankedSales rs
    WHERE 
        rs.rnk <= 5
)

SELECT 
    f.ws_item_sk,
    COUNT(DISTINCT f.ws_order_number) AS order_count,
    SUM(f.ws_sales_price) AS total_sales,
    AVG(f.ws_net_paid) AS average_net_paid,
    MAX(f.higher_sales_count) AS max_higher_sales_count,
    MIN(f.ws_net_paid) AS min_net_paid,
    CASE 
        WHEN COUNT(f.ws_order_number) > 0 THEN 
            SUM(f.ws_net_paid) / COUNT(f.ws_order_number)
        ELSE 
            NULL 
    END AS avg_per_order_net_paid
FROM 
    FilteredSales f
GROUP BY 
    f.ws_item_sk
HAVING 
    SUM(f.ws_sales_price) > 1000 OR MIN(f.ws_net_paid) IS NULL
ORDER BY 
    total_sales DESC, avg_per_order_net_paid NULLS LAST
LIMIT 10;