
WITH RECURSIVE CTE_Sales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk 
    HAVING 
        SUM(ws_ext_sales_price) > 1000
    UNION ALL
    SELECT 
        cs_item_sk, 
        SUM(cs_ext_sales_price) AS total_sales
    FROM 
        catalog_sales 
    WHERE 
        cs_item_sk IN (SELECT ws_item_sk FROM web_sales)
    GROUP BY 
        cs_item_sk 
    HAVING 
        SUM(cs_ext_sales_price) > 1000
), 
Sales_With_Rank AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        CTE.total_sales,
        ROW_NUMBER() OVER (ORDER BY CTE.total_sales DESC) AS sales_rank
    FROM 
        CTE_Sales AS CTE
    JOIN 
        item ON item.i_item_sk = CTE.ws_item_sk 
)
SELECT 
    ca.ca_country,
    SUM(Sales_With_Rank.total_sales) AS country_sales,
    COUNT(DISTINCT Sales_With_Rank.i_item_id) AS unique_items_sold
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store_sales AS ss ON ss.ss_customer_sk = c.c_customer_sk
JOIN 
    Sales_With_Rank ON Sales_With_Rank.i_item_sk = ss.ss_item_sk
WHERE 
    ca.ca_state = 'CA'
    AND (Sales_With_Rank.sales_rank <= 10 OR Sales_With_Rank.total_sales IS NULL)
GROUP BY 
    ca.ca_country
HAVING 
    SUM(Sales_With_Rank.total_sales) > 5000 
ORDER BY 
    country_sales DESC;
