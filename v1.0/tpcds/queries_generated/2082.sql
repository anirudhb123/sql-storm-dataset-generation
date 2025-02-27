
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws
)

SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_sales_price) AS total_sales,
    MAX(RankSales.rank) AS max_rank
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    RankedSales ON c.c_customer_sk = RankedSales.ws_web_page_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
WHERE 
    ca.ca_state = 'CA'
    AND (ws.ws_sales_price > 0 OR ws.ws_quantity IS NULL)
GROUP BY 
    c.c_customer_id, ca.ca_city
HAVING 
    SUM(ws.ws_quantity) > 10
UNION ALL
SELECT 
    'N/A' AS c_customer_id,
    ca.ca_city,
    COUNT(DISTINCT ws.ws_order_number) AS total_quantity,
    SUM(ws.ws_sales_price) AS total_sales,
    NULL AS max_rank
FROM 
    customer_address ca
LEFT JOIN 
    web_sales ws ON ca.ca_address_sk = ws.ws_bill_addr_sk
WHERE 
    ca.ca_state IS NULL
GROUP BY 
    ca.ca_city
ORDER BY 
    total_sales DESC;
