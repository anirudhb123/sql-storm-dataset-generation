WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        d.d_year,
        d.d_moy,
        d.d_week_seq,
        ROW_NUMBER() OVER (PARTITION BY d.d_year, d.d_moy ORDER BY ws.ws_net_profit DESC) AS rnk
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2000 AND ws.ws_net_profit > 0
), TopSales AS (
    SELECT 
        sd.ws_order_number,
        sd.ws_item_sk,
        sd.ws_sales_price,
        sd.ws_quantity,
        sd.ws_net_profit
    FROM 
        SalesData sd
    WHERE 
        sd.rnk <= 5  
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    SUM(ts.ws_net_profit) AS total_profit,
    COUNT(ts.ws_order_number) AS total_orders,
    MAX(ts.ws_sales_price) AS max_sale_price,
    STRING_AGG(DISTINCT i.i_product_name, ', ') AS sold_products
FROM 
    TopSales ts
JOIN 
    customer c ON ts.ws_order_number = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    item i ON ts.ws_item_sk = i.i_item_sk
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city
HAVING 
    SUM(ts.ws_net_profit) > 1000  
ORDER BY 
    total_profit DESC;