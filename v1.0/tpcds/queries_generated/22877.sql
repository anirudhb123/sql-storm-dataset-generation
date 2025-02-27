
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) as rn
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
top_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        DENSE_RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        sales_data sd
    WHERE 
        sd.rn = 1
),
sales_with_discount AS (
    SELECT 
        ts.ws_item_sk,
        ts.total_quantity,
        ts.total_sales,
        CASE 
            WHEN ts.sales_rank < 10 THEN ts.total_sales * 0.90
            WHEN ts.sales_rank < 20 THEN ts.total_sales * 0.95
            ELSE ts.total_sales
        END AS adjusted_sales
    FROM 
        top_sales ts
)
SELECT 
    ca.ca_city,
    SUM(sw.adjusted_sales) AS total_adjusted_sales,
    AVG(sw.total_quantity) AS average_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    MAX(t.d_date) AS last_sale_date
FROM 
    sales_with_discount sw
JOIN 
    web_sales ws ON sw.ws_item_sk = ws.ws_item_sk
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    date_dim t ON ws.ws_sold_date_sk = t.d_date_sk
GROUP BY 
    ca.ca_city
HAVING 
    SUM(sw.adjusted_sales) IS NOT NULL
ORDER BY 
    total_adjusted_sales DESC
LIMIT 10 OFFSET 5
UNION ALL
SELECT 
    'TOTALS' AS ca_city,
    SUM(sw.adjusted_sales) AS total_adjusted_sales,
    AVG(sw.total_quantity) AS average_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    NULL AS last_sale_date
FROM 
    sales_with_discount sw
JOIN 
    web_sales ws ON sw.ws_item_sk = ws.ws_item_sk
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    date_dim t ON ws.ws_sold_date_sk = t.d_date_sk
WHERE 
    sw.adjusted_sales IS NOT NULL;
