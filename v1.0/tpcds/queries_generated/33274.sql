
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
), 
item_details AS (
    SELECT 
        i_item_sk,
        i_product_name,
        i_category,
        i_current_price
    FROM 
        item
)
SELECT 
    d.d_date AS sales_date,
    id.i_product_name,
    id.i_category,
    COALESCE(SUM(sc.total_sales), 0) AS total_sales_amount,
    COUNT(sc.ws_item_sk) AS number_of_sales,
    AVG(CASE WHEN sc.total_sales > 100 THEN sc.total_sales END) AS avg_high_sales,
    MAX(id.i_current_price) OVER (PARTITION BY id.i_category) AS max_price_in_category
FROM 
    date_dim d
LEFT JOIN 
    sales_cte sc ON d.d_date_sk = sc.ws_sold_date_sk
LEFT JOIN 
    item_details id ON sc.ws_item_sk = id.i_item_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    d.d_date, id.i_product_name, id.i_category
HAVING 
    total_sales_amount > (SELECT AVG(total_sales) FROM sales_cte)
ORDER BY 
    total_sales_amount DESC;
