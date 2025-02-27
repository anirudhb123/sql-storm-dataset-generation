
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_sales_price, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        COALESCE(cs_total_sales.total_sales, 0) AS catalog_sales_total,
        COALESCE(ss_total_sales.total_sales, 0) AS store_sales_total,
        (rs.ws_sales_price + COALESCE(cs_total_sales.total_sales, 0) + COALESCE(ss_total_sales.total_sales, 0)) AS grand_total_sales
    FROM 
        RankedSales rs
    LEFT JOIN (
        SELECT 
            cs_item_sk, 
            SUM(cs_ext_sales_price) AS total_sales 
        FROM 
            catalog_sales 
        GROUP BY 
            cs_item_sk
    ) cs_total_sales ON rs.ws_item_sk = cs_total_sales.cs_item_sk
    LEFT JOIN (
        SELECT 
            ss_item_sk, 
            SUM(ss_ext_sales_price) AS total_sales 
        FROM 
            store_sales 
        GROUP BY 
            ss_item_sk
    ) ss_total_sales ON rs.ws_item_sk = ss_total_sales.ss_item_sk
    WHERE 
        price_rank = 1
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    SUM(ts.grand_total_sales) AS overall_sales,
    AVG(ts.grand_total_sales) AS average_sales,
    MAX(ts.grand_total_sales) AS max_sales,
    MIN(ts.grand_total_sales) AS min_sales
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    TopSales ts ON ts.ws_item_sk IN (
        SELECT 
            ws_item_sk 
        FROM 
            web_sales 
        WHERE 
            ws_bill_customer_sk = c.c_customer_sk
    )
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 5 AND
    AVG(ts.grand_total_sales) > 100
ORDER BY 
    overall_sales DESC
LIMIT 10;
