
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_quantity DESC) AS rnk
    FROM 
        web_sales
),
TotalSales AS (
    SELECT 
        ws_ship_mode_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_ship_mode_sk
),
ItemSales AS (
    SELECT 
        i_item_sk,
        i_product_name,
        SUM(ws_ext_sales_price) AS total_item_sales
    FROM 
        web_sales
    JOIN 
        item ON ws_item_sk = i_item_sk
    GROUP BY 
        i_item_sk, i_product_name
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(ISNULL(ws.net_profit, 0)) AS total_net_profit,
    AVG(ISNULL(ws.ws_sales_price, 0)) AS avg_sales_price,
    MIN(r.total_item_sales) AS min_item_sales,
    MAX(r.total_item_sales) AS max_item_sales,
    DENSE_RANK() OVER (ORDER BY SUM(ISNULL(ws.net_profit, 0)) DESC) AS sales_rank
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    ItemSales r ON ws.ws_item_sk = r.i_item_sk 
GROUP BY 
    c.c_customer_id, ca.ca_city
HAVING 
    SUM(ISNULL(ws.net_profit, 0)) > 1000 AND AVG(ISNULL(ws.ws_sales_price, 0)) < 50
ORDER BY 
    sales_rank, ca.ca_city;
