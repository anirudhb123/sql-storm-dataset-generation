
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_net_profit DESC) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) 
                                FROM date_dim 
                                WHERE d_year = 2023)
)

SELECT
    COALESCE(c.c_first_name, 'Unknown') AS customer_name,
    ca.ca_city AS address_city,
    SUM(CASE 
            WHEN sr_return_quantity IS NULL THEN 0 
            ELSE sr_return_quantity 
        END) AS total_returned_items,
    AVG(NULLIF(ws.ws_net_paid_inc_tax, 0)) AS avg_net_paid,
    AVG(NULLIF(ws.ws_sales_price, 0)) FILTER (WHERE ws.ws_sales_price IS NOT NULL) AS avg_sales_price,
    COUNT(DISTINCT CASE 
            WHEN ws.ws_net_profit < 0 THEN ws.ws_order_number 
            ELSE NULL 
        END) AS total_negative_profit_orders,
    CASE 
        WHEN SUM(ws.ws_quantity) > 100 THEN 'High Volume'
        WHEN SUM(ws.ws_quantity) BETWEEN 50 AND 100 THEN 'Moderate Volume'
        ELSE 'Low Volume' 
    END AS sales_volume_category
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
LEFT JOIN 
    ranked_sales rs ON rs.web_site_id = 'WEB01' AND rs.rnk <= 5
GROUP BY 
    c.c_first_name, ca.ca_city
HAVING 
    COUNT(DISTINCT sr.sr_ticket_number) > 2
ORDER BY 
    total_returned_items DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
