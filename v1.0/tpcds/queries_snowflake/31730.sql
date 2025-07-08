
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rn
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
    
    UNION ALL
    
    SELECT 
        ss.ws_sold_date_sk,
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ss.rn
    FROM 
        sales_summary ss
    INNER JOIN 
        web_sales ws ON ss.ws_item_sk = ws.ws_item_sk AND ss.ws_sold_date_sk < ws.ws_sold_date_sk
)

SELECT 
    ca.ca_city,
    cd.cd_gender,
    SUM(ss.total_sales) AS city_sales,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    AVG(CASE WHEN cd.cd_marital_status = 'M' THEN cd.cd_purchase_estimate ELSE NULL END) AS avg_purchase_married,
    COUNT(DISTINCT CASE WHEN cd.cd_credit_rating = 'Excellent' THEN c.c_customer_sk END) AS excellent_credit_customers
FROM 
    sales_summary ss
JOIN 
    customer c ON ss.ws_item_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ss.rn = 1
GROUP BY 
    ca.ca_city, cd.cd_gender
HAVING 
    SUM(ss.total_sales) > (SELECT AVG(total_sales) FROM sales_summary)
ORDER BY 
    city_sales DESC
LIMIT 10;
