
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(*) AS sales_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM 
        web_sales 
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
MaxSales AS (
    SELECT 
        ws_item_sk,
        MAX(total_sales) AS max_sales,
        MIN(sales_count) AS min_sales_count
    FROM 
        SalesCTE
    WHERE 
        rn <= 5
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(MAX(ms.max_sales), 0) AS max_sales,
    COALESCE(A.sales_count, 0) AS total_sales_count,
    ROUND(COALESCE(MAX(ms.max_sales), 0) / NULLIF(COALESCE(A.sales_count, 1), 0), 2) AS sales_per_sales_count,
    CONCAT(e.c_first_name, ' ', e.c_last_name) AS top_selling_rep
FROM 
    item i
LEFT JOIN 
    MaxSales ms ON i.i_item_sk = ms.ws_item_sk
LEFT JOIN 
    (SELECT 
        ws_item_sk, COUNT(*) AS sales_count 
     FROM 
        web_sales 
     GROUP BY 
        ws_item_sk) A ON i.i_item_sk = A.ws_item_sk
LEFT JOIN 
    customer e ON e.c_customer_sk = (
        SELECT 
            e1.c_customer_sk 
        FROM 
            store_sales s 
        JOIN 
            customer e1 ON e1.c_customer_sk = s.ss_customer_sk 
        WHERE 
            s.ss_item_sk = i.i_item_sk 
        GROUP BY 
            e1.c_customer_sk 
        ORDER BY 
            SUM(s.ss_sales_price) DESC 
        LIMIT 1
    )
GROUP BY 
    i.i_item_id, 
    i.i_item_desc, 
    A.sales_count 
ORDER BY 
    max_sales DESC, 
    total_sales_count DESC;
