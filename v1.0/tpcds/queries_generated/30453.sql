
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_sales_price, 
        ws_quantity, 
        ws_net_profit,
        1 AS level,
        ws_sales_price * ws_quantity AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    
    UNION ALL

    SELECT 
        cs_item_sk, 
        cs_order_number, 
        cs_sales_price, 
        cs_quantity,
        cs_net_profit,
        level + 1 AS level,
        cs_sales_price * cs_quantity AS total_sales
    FROM 
        catalog_sales
    WHERE 
        cs_order_number IN (SELECT ws_order_number FROM web_sales) 
        AND cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),

Aggregate_sales AS (
    SELECT 
        ws_item_sk,
        SUM(total_sales) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(total_sales) DESC) AS sales_rank
    FROM 
        Sales_CTE
    GROUP BY 
        ws_item_sk
)

SELECT 
    a.ws_item_sk,
    i.i_item_desc,
    a.total_sales,
    a.total_profit,
    a.order_count,
    CASE 
        WHEN a.total_sales IS NULL THEN 'No Sales'
        WHEN a.total_sales < 1000 THEN 'Low Sales'
        WHEN a.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Sales'
        ELSE 'High Sales'
    END AS sales_category,
    COALESCE(c.cc_call_center_id, 'N/A') AS call_center_id
FROM 
    Aggregate_sales a
JOIN 
    item i ON a.ws_item_sk = i.i_item_sk
LEFT JOIN 
    call_center c ON a.sales_rank <= 10 AND c.cc_call_center_sk = (SELECT MIN(cc_call_center_sk) FROM call_center)
WHERE 
    a.total_sales > 2000
ORDER BY 
    a.total_sales DESC
LIMIT 50;
