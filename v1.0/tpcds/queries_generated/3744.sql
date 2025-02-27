
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_price,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk) AS total_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND ws.ws_sold_date_sk <= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31') 
)
SELECT 
    ca.ca_city,
    SUM(rs.ws_sales_price) AS total_sales,
    COUNT(DISTINCT rs.ws_order_number) AS total_orders,
    MAX(rs.ws_sales_price) AS max_single_sale,
    AVG(rs.ws_sales_price) AS average_sale,
    CASE 
        WHEN SUM(rs.ws_sales_price) > 100000 THEN 'High Sales'
        WHEN SUM(rs.ws_sales_price) BETWEEN 50000 AND 100000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    RankedSales rs
JOIN 
    customer c ON rs.ws_order_number = c.c_customer_id
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    rs.rank_price = 1
    AND c.c_preferred_cust_flag = 'Y'
GROUP BY 
    ca.ca_city
HAVING 
    AVG(rs.ws_sales_price) IS NOT NULL
    AND MAX(rs.ws_sales_price) > 100
ORDER BY 
    total_sales DESC
LIMIT 10;
