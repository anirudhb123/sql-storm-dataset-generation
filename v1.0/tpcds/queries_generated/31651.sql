
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk, 
        ws_sales_price, 
        ws_quantity, 
        1 AS depth 
    FROM 
        web_sales 
    WHERE 
        ws_sales_price IS NOT NULL
    UNION ALL
    SELECT 
        c.cs_item_sk, 
        c.cs_sales_price, 
        c.cs_quantity,
        s.depth + 1
    FROM 
        catalog_sales c 
    JOIN 
        SalesCTE s ON c.cs_item_sk = s.ws_item_sk 
    WHERE 
        c.cs_sales_price IS NOT NULL 
        AND s.depth < 10
),
RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales_price, 
        SUM(ws_quantity) AS total_quantity,
        RANK() OVER (ORDER BY SUM(ws_sales_price) DESC) AS sales_rank 
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    COALESCE(SUM(s.total_sales_price), 0) AS total_web_sales,
    COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_catalog_sales,
    COALESCE(SUM(s.total_quantity), 0) AS total_quantity_sold
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    RankedSales s ON c.c_customer_sk = s.ws_item_sk
LEFT JOIN 
    catalog_sales cs ON s.ws_item_sk = cs.cs_item_sk
WHERE 
    ca.ca_state = 'CA' 
    AND c.c_birth_year > 1985
GROUP BY 
    ca.ca_city
HAVING 
    total_web_sales > 1000
ORDER BY 
    total_web_sales DESC;
