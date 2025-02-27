
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL
),
AggregateSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        COUNT(DISTINCT ws_sold_date_sk) AS sale_days
    FROM web_sales
    GROUP BY ws_item_sk
),
PopularItems AS (
    SELECT 
        a.ws_item_sk,
        a.total_sales,
        a.sale_days,
        RANK() OVER (ORDER BY a.total_sales DESC, a.sale_days DESC) AS sales_rank
    FROM AggregateSales a
    JOIN RankedSales r ON a.ws_item_sk = r.ws_item_sk
    WHERE r.rank <= 5
)
SELECT 
    p.ws_item_sk,
    p.total_sales,
    p.sale_days,
    COALESCE(NULLIF(p.sale_days, 0), 1) AS effective_sale_days,
    CASE 
        WHEN p.total_sales > 100000 THEN 'High Seller'
        WHEN p.total_sales BETWEEN 50000 AND 100000 THEN 'Medium Seller'
        ELSE 'Low Seller'
    END AS sales_category,
    (SELECT COUNT(*) 
     FROM store_sales ss 
     WHERE ss.ss_item_sk = p.ws_item_sk AND ss.ss_sales_price IS NOT NULL) AS store_sales_count,
    (SELECT SUM(ss.net_profit) 
     FROM store_sales ss 
     WHERE ss.ss_item_sk = p.ws_item_sk AND ss.ss_net_paid IS NOT NULL) AS total_store_net_profit
FROM PopularItems p
LEFT JOIN item i ON p.ws_item_sk = i.i_item_sk
WHERE 
    i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_item_sk IS NOT NULL)
    AND (SELECT COUNT(*) FROM inventory inv WHERE inv.inv_item_sk = p.ws_item_sk) > 0
ORDER BY p.total_sales DESC, p.sale_days DESC;
