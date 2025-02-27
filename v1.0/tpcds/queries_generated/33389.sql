
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    UNION ALL
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        st.level + 1
    FROM 
        web_sales ws
    JOIN 
        SalesCTE st ON ws.ws_sold_date_sk = st.ws_sold_date_sk - INTERVAL '1 day'
)
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS customer_count,
    COUNT(DISTINCT ws_item_sk) AS unique_items_sold,
    SUM(ws_quantity) AS total_quantity_sold,
    SUM(ws_sales_price * ws_quantity) AS total_sales_value,
    AVG(ws_sales_price) AS avg_sales_price,
    MAX(ws_sales_price) - MIN(ws_sales_price) AS price_range,
    RANK() OVER (PARTITION BY ca_state ORDER BY SUM(ws_sales_price * ws_quantity) DESC) AS state_sales_rank
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca_state IS NOT NULL 
    AND ws_item_sk IN (SELECT ws_item_sk FROM SalesCTE WHERE level <= 5)
GROUP BY 
    ca_state
HAVING 
    COUNT(DISTINCT c_customer_sk) > 10
ORDER BY 
    total_sales_value DESC;
