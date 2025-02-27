
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        ds.d_date_sk,
        sd.ws_item_sk,
        sd.total_quantity + COALESCE((SELECT SUM(ws_quantity) FROM web_sales WHERE ws_sold_date_sk < ds.d_date_sk AND ws_item_sk = sd.ws_item_sk), 0),
        sd.total_profit + COALESCE((SELECT SUM(ws_net_profit) FROM web_sales WHERE ws_sold_date_sk < ds.d_date_sk AND ws_item_sk = sd.ws_item_sk), 0)
    FROM 
        sales_data sd
    JOIN 
        date_dim ds ON sd.ws_sold_date_sk = ds.d_date_sk
    WHERE 
        ds.d_date_sk < (SELECT MAX(d_date_sk) FROM date_dim)
)
SELECT 
    ca.city,
    ca.state,
    SUM(sd.total_quantity) AS total_sales_quantity,
    AVG(sd.total_profit) AS avg_profit,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    CASE 
        WHEN AVG(sd.total_profit) IS NULL THEN 'No Transactions'
        WHEN AVG(sd.total_profit) < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status
FROM 
    sales_data sd
JOIN 
    customer c ON sd.ws_item_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
    ca.city, ca.state
HAVING 
    total_sales_quantity > 1000
ORDER BY 
    total_sales_quantity DESC
LIMIT 10;
