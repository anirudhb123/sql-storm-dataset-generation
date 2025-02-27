
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales AS ws
    INNER JOIN 
        web_page AS wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN 
        catalog_sales AS cs ON ws.ws_item_sk = cs.cs_item_sk
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'U') AS customer_gender,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
top_returned_items AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns
    FROM 
        store_returns AS sr
    GROUP BY 
        sr.sr_item_sk
    HAVING 
        SUM(sr.sr_return_quantity) > 10
),
formatted_addresses AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT_WS(', ', NULLIF(ca.ca_street_number, ''), ca.ca_street_name, ca.ca_city, ca.ca_state, ca.ca_zip) AS full_address
    FROM 
        customer_address AS ca
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.customer_gender,
    ra.total_quantity,
    ta.total_returns,
    fa.full_address,
    CASE 
        WHEN ca.avg_order_value > 100 THEN 'High Value'
        WHEN ca.avg_order_value BETWEEN 50 AND 100 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    customer AS c
JOIN 
    customer_analysis AS ca ON c.c_customer_sk = ca.c_customer_sk
LEFT JOIN 
    ranked_sales AS ra ON ra.web_site_sk = (SELECT wp.web_site_sk FROM web_page wp ORDER BY RAND() LIMIT 1)
LEFT JOIN 
    top_returned_items AS ta ON ta.sr_item_sk = (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk ORDER BY ws.ws_net_paid LIMIT 1)
LEFT JOIN 
    formatted_addresses AS fa ON fa.ca_address_sk = c.c_current_addr_sk
WHERE 
    ca.order_count > 5
ORDER BY 
    c.c_last_name, c.c_first_name;
