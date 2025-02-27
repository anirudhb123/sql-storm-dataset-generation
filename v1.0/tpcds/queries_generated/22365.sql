
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        SUM(ws.ws_net_paid) OVER (PARTITION BY ws.web_site_sk) AS total_net_paid
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
)
SELECT 
    ca.ca_city,
    SUM(rs.ws_sales_price) AS total_sales,
    COUNT(DISTINCT rs.ws_order_number) AS unique_orders,
    AVG(CASE 
        WHEN rs.ws_net_paid IS NOT NULL THEN rs.ws_net_paid 
        ELSE 0 
    END) AS avg_net_paid,
    COUNT(CASE 
        WHEN rs.rank_profit = 1 THEN 1 
    END) AS top_profit_orders
FROM 
    Customer_Demographics cd
JOIN 
    customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    RankedSales rs ON c.c_customer_sk = rs.web_site_sk
WHERE 
    cd.cd_gender IN ('M', 'F') 
    AND (rs.total_net_paid > 100 OR rs.ws_sales_price BETWEEN 50 AND 100)
GROUP BY 
    ca.ca_city
HAVING 
    SUM(rs.ws_sales_price) > 5000
ORDER BY 
    total_sales DESC
LIMIT 10;
