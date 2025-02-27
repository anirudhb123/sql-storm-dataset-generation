
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ws_sales_price * ws_quantity AS total_sales,
        1 AS sales_level
    FROM
        web_sales
    WHERE
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    
    UNION ALL
    
    SELECT
        cs_item_sk,
        cs_order_number,
        cs_sales_price,
        cs_quantity,
        cs_sales_price * cs_quantity AS total_sales,
        sales_level + 1
    FROM
        catalog_sales
    WHERE
        cs_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 7 AND (SELECT MAX(d_date_sk) FROM date_dim)
)
SELECT 
    w.web_site_id,
    SUM(s.total_sales) AS total_sales,
    AVG(s.total_sales) AS avg_sales,
    COUNT(DISTINCT s.ws_order_number) AS unique_orders,
    STRING_AGG(DISTINCT c.c_country, ', ') AS countries_sold_to,
    ROW_NUMBER() OVER (PARTITION BY w.web_site_id ORDER BY SUM(s.total_sales) DESC) AS sales_rank
FROM 
    web_site w
LEFT JOIN 
    SalesCTE s ON w.web_site_sk = s.ws_item_sk
LEFT JOIN 
    customer c ON s.ws_bill_customer_sk = c.c_customer_sk
GROUP BY 
    w.web_site_id
HAVING 
    SUM(s.total_sales) > (SELECT AVG(total_sales) FROM (SELECT SUM(ws_sales_price * ws_quantity) AS total_sales FROM web_sales GROUP BY ws_order_number) AS daily_avg)
ORDER BY 
    total_sales DESC;
