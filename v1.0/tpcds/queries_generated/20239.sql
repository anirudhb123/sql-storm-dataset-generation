
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_quantity DESC) AS rank_quantity
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
),
qualified_sales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_quantity,
        rs.ws_net_profit,
        CASE 
            WHEN rs.rank_profit = 1 AND rs.rank_quantity = 1 THEN 'Top Seller'
            WHEN rs.rank_profit = 1 THEN 'Highest Profit'
            WHEN rs.rank_quantity = 1 THEN 'Best Seller'
            ELSE 'Moderate Seller' 
        END AS sale_category
    FROM 
        ranked_sales rs
)
SELECT 
    ca.ca_country,
    SUM(qs.ws_net_profit) AS total_profit,
    COUNT(DISTINCT qs.ws_order_number) AS total_orders,
    STRING_AGG(DISTINCT qs.sale_category, ', ') AS sale_categories
FROM 
    qualified_sales qs
JOIN 
    item i ON qs.ws_item_sk = i.i_item_sk
LEFT JOIN 
    customer c ON c.c_customer_sk = qs.ws_order_number
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
WHERE 
    (c.c_birth_year IS NULL OR c.c_birth_year > 1980)
    AND (i.i_current_price BETWEEN 10.00 AND 500.00 OR i.i_item_desc LIKE '%gadget%')
    AND (qs.ws_net_profit IS NOT NULL AND qs.ws_net_profit > 0)
    AND (NOT (qs.ws_quantity IS NULL) OR (qs.ws_quantity IS NULL AND qs.ws_net_profit < 100))
GROUP BY 
    ca.ca_country
HAVING 
    total_profit > 10000.00 AND COUNT(DISTINCT qs.ws_order_number) > 5
ORDER BY 
    total_profit DESC
FETCH FIRST 10 ROWS ONLY;
