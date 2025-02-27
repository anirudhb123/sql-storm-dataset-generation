
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(d_date_sk) 
                              FROM date_dim 
                              WHERE d_date BETWEEN DATEADD(day, -1, GETDATE()) AND GETDATE())
),
SalesSummary AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
        SUM(rs.ws_quantity) AS total_quantity,
        COUNT(DISTINCT rs.ws_item_sk) AS unique_items
    FROM RankedSales rs
    WHERE rs.rn <= 10
    GROUP BY rs.ws_item_sk
)
SELECT 
    CASE 
        WHEN ss.total_sales IS NULL THEN 'No Sales'
        WHEN ss.total_sales > 1000 THEN 'High Sales'
        WHEN ss.total_sales BETWEEN 500 AND 1000 THEN 'Moderate Sales'
        ELSE 'Low Sales'
    END AS sales_category,
    i.i_item_id,
    i.i_item_desc,
    ss.total_sales,
    ss.total_quantity
FROM SalesSummary ss
LEFT JOIN item i ON ss.ws_item_sk = i.i_item_sk
WHERE ss.total_quantity IS NOT NULL
AND (i.i_item_desc LIKE '%special%' OR ss.total_sales IS NOT NULL)
ORDER BY total_sales DESC
LIMIT 50;

SELECT 
    COUNT(*) AS total_returned,
    sr_reason_sk,
    r.r_reason_desc
FROM store_returns sr
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE sr_return_quantity > 0
AND sr_returned_date_sk IN (SELECT d_date_sk 
                             FROM date_dim 
                             WHERE d_dow = 6 AND d_date <= (CURRENT_DATE - INTERVAL '1 week'))
GROUP BY sr_reason_sk, r.r_reason_desc
HAVING COUNT(*) > 10
ORDER BY total_returned DESC;

SELECT 
    s.s_store_name, 
    SUM(ss.ss_net_profit) AS total_store_profit 
FROM store s
JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
WHERE s.s_state = 'CA'
AND ss.ss_sold_date_sk = (SELECT MAX(d_date_sk) 
                          FROM date_dim 
                          WHERE d_date < CURRENT_DATE)
GROUP BY s.s_store_name
HAVING total_store_profit > 10000
ORDER BY total_store_profit DESC
FETCH FIRST 10 ROWS ONLY;
