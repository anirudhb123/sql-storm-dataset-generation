
WITH RECURSIVE SalesCTE AS (
    SELECT 
        cs_sold_date_sk, 
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS order_count,
        cs_item_sk
    FROM catalog_sales
    GROUP BY cs_sold_date_sk, cs_item_sk
    UNION ALL
    SELECT 
        cs_sold_date_sk + 1, 
        total_sales + (SELECT COALESCE(SUM(cs_ext_sales_price), 0) FROM catalog_sales WHERE cs_sold_date_sk = s.cs_sold_date_sk + 1 AND cs_item_sk = s.cs_item_sk),
        order_count,
        cs_item_sk
    FROM SalesCTE s
    WHERE cs_sold_date_sk < (SELECT MAX(cs_sold_date_sk) FROM catalog_sales)
)
SELECT 
    d.d_date AS sale_date, 
    s.cs_item_sk,
    s.total_sales,
    s.order_count,
    RANK() OVER (PARTITION BY s.cs_item_sk ORDER BY s.total_sales DESC) AS sales_rank,
    i.i_item_desc,
    ca_city,
    ca_state
FROM SalesCTE s
JOIN date_dim d ON s.cs_sold_date_sk = d.d_date_sk
JOIN item i ON s.cs_item_sk = i.i_item_sk
LEFT JOIN customer_address ca ON i.i_item_sk = ca.ca_address_sk
WHERE s.total_sales > 1000 
    AND d.d_year = 2023
ORDER BY sale_date, total_sales DESC
LIMIT 100;
