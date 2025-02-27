
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        ws_sold_date_sk
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 30
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk, 
        total_sales + cs_ext_sales_price AS total_sales,
        cs_sold_date_sk
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 1 AND 30
        AND cs_item_sk IN (SELECT ws_item_sk FROM sales_cte)
),
ranked_sales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        sales_cte.total_sales,
        RANK() OVER (ORDER BY sales_cte.total_sales DESC) AS sales_rank
    FROM 
        sales_cte
    JOIN 
        item ON sales_cte.ws_item_sk = item.i_item_sk
)
SELECT 
    CONCAT_WS(' ', c.c_first_name, c.c_last_name) AS customer_name,
    r.sales_rank,
    r.i_product_name,
    r.total_sales
FROM 
    ranked_sales r
INNER JOIN 
    customer c ON c.c_customer_sk IN (
        SELECT DISTINCT ws_ship_customer_sk
        FROM web_sales ws
        WHERE ws_item_sk IN (SELECT ws_item_sk FROM sales_cte)
    )
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
WHERE 
    ca.ca_city IS NOT NULL 
    AND (c.c_birth_year IS NULL OR c.c_birth_year > 1980)
ORDER BY 
    r.sales_rank;
