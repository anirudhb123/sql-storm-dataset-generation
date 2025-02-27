
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) as rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_ext_sales_price
    FROM 
        RankedSales rs
    WHERE 
        rs.rn = 1
)
SELECT 
    ca.city AS "Customer City",
    ca.state AS "Customer State",
    SUM(ts.ws_ext_sales_price) AS "Total Sales",
    COUNT(DISTINCT ts.ws_order_number) AS "Unique Orders",
    MAX(ts.ws_ext_sales_price) AS "Highest Sale"
FROM 
    TopSales ts
JOIN 
    customer_address ca ON ts.ws_order_number = ca.ca_address_sk
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
WHERE 
    c.c_customer_sk IS NOT NULL
GROUP BY 
    ca.city, ca.state
HAVING 
    SUM(ts.ws_ext_sales_price) > 1000
ORDER BY 
    "Total Sales" DESC, "Customer City";
