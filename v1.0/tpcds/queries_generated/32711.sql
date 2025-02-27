
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
),
FilteredSales AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        S.total_sales,
        S.order_count
    FROM 
        item i
    JOIN 
        SalesCTE S ON i.i_item_sk = S.ws_item_sk
    WHERE 
        S.total_sales > 1000
),
TopNItems AS (
    SELECT 
        f.*,
        DENSE_RANK() OVER (ORDER BY f.total_sales DESC) AS sales_rank
    FROM 
        FilteredSales f
    WHERE 
        f.order_count > 5
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    t.total_sales,
    CASE 
        WHEN t.sales_rank <= 5 THEN 'Top Seller'
        ELSE 'Regular'
    END AS seller_category
FROM 
    TopNItems t
JOIN 
    customer c ON c.c_customer_sk IN (
        SELECT DISTINCT ws_bill_customer_sk FROM web_sales 
        WHERE ws_item_sk = t.ws_item_sk
    )
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store_sales ss ON ss.ss_item_sk = t.ws_item_sk AND ss.ss_sold_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2022
    )
WHERE 
    ca.ca_city IS NOT NULL
ORDER BY 
    t.total_sales DESC,
    c.c_last_name,
    c.c_first_name;
