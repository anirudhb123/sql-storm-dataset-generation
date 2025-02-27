
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rank
    FROM
        web_sales
    GROUP BY 
        ws_item_sk
),
top_sales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        sd.total_quantity,
        sd.total_sales,
        CASE 
            WHEN sd.total_sales > 1000 THEN 'High Sales'
            WHEN sd.total_sales > 500 THEN 'Medium Sales'
            ELSE 'Low Sales'
        END AS sales_category
    FROM
        sales_data sd
    JOIN 
        item ON sd.ws_item_sk = item.i_item_sk
    WHERE 
        sd.rank = 1
)
SELECT 
    ca.city,
    ca.state,
    ts.sales_category,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    SUM(ts.total_sales) AS total_sales_amount
FROM 
    top_sales ts
JOIN 
    web_site ws ON ws.web_site_sk = ts.ws_warehouse_sk
JOIN 
    customer c ON c.c_current_addr_sk = ws.web_site_sk
JOIN 
    customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    store s ON s.s_store_sk = c.c_current_addr_sk
GROUP BY 
    ca.city, 
    ca.state, 
    ts.sales_category
HAVING 
    SUM(ts.total_sales) > 500
UNION ALL
SELECT
    ca.city,
    ca.state,
    'Total Sales',
    COUNT(DISTINCT c.c_customer_id),
    SUM(ts.total_sales)
FROM 
    top_sales ts
JOIN 
    customer c ON c.c_current_addr_sk = ts.ws_warehouse_sk
JOIN 
    customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
GROUP BY 
    ca.city, 
    ca.state
ORDER BY 
    total_sales_amount DESC;
