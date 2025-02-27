
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk BETWEEN 1 AND 100
), 
SalesSummary AS (
    SELECT 
        rs.ws_item_sk,
        COUNT(*) AS total_sales,
        SUM(rs.ws_sales_price) AS total_revenue,
        MAX(rs.ws_sales_price) AS highest_sale
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 5
    GROUP BY 
        rs.ws_item_sk
)
SELECT 
    s.s_store_name,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_revenue, 0) AS total_revenue,
    ss.highest_sale
FROM 
    store s
LEFT JOIN 
    SalesSummary ss ON ss.ws_item_sk IN (
        SELECT DISTINCT cs_item_sk 
        FROM catalog_sales 
        WHERE cs_bill_customer_sk IS NOT NULL 
          AND cs_sold_date_sk IN (
              SELECT d_date_sk 
              FROM date_dim 
              WHERE d_year = 2023
          ))
ORDER BY 
    s.s_store_name ASC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;

SELECT 
    ca.ca_city,
    COUNT(*) AS customer_count
FROM 
    customer c
INNER JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    c.c_birth_year IS NOT NULL 
    AND ca.ca_state IS NOT NULL 
    AND ca.ca_country = 'USA'
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(*) > (SELECT COUNT(*) FROM customer WHERE c_current_cdemo_sk IS NULL)
EXCEPT
SELECT 
    ca.ca_city
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
WHERE 
    c.c_current_addr_sk IS NULL
    AND ca.ca_country <> 'USA';
