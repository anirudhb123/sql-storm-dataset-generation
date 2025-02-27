
WITH RECURSIVE revenue_summary AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        1 AS level
    FROM web_sales
    GROUP BY ws_sold_date_sk
    
    UNION ALL

    SELECT 
        w.ws_sold_date_sk,
        r.total_sales + SUM(ws_ext_sales_price) AS total_sales,
        r.total_quantity + SUM(ws_quantity) AS total_quantity,
        level + 1
    FROM web_sales w
    JOIN revenue_summary r ON w.ws_sold_date_sk = r.ws_sold_date_sk + 1
    GROUP BY w.ws_sold_date_sk, r.total_sales, r.total_quantity, level
)

SELECT 
    d.d_date,
    COALESCE(r.total_sales, 0) AS daily_sales,
    COALESCE(r.total_quantity, 0) AS daily_quantity,
    CASE 
        WHEN r.total_sales IS NOT NULL THEN r.total_sales * 0.05 
        ELSE 0 
    END AS tax_amount,
    CONCAT('Sales: ', COALESCE(r.total_sales, 0), 
           ', Quantity: ', COALESCE(r.total_quantity, 0)) AS summary_info,
    CASE 
        WHEN r.total_quantity IS NULL OR r.total_quantity = 0 THEN 'No sales recorded for this day'
        ELSE 'Sales data available'
    END AS status_message
FROM date_dim d
LEFT JOIN revenue_summary r ON d.d_date_sk = r.ws_sold_date_sk
WHERE d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY d.d_date ASC;
