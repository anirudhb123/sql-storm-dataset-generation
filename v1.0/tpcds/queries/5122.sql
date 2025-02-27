
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        AVG(ws.ws_net_profit) AS average_net_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    w.w_warehouse_id,
    w.w_warehouse_name,
    ss.total_quantity_sold,
    ss.total_sales_amount,
    ss.average_net_profit,
    c.c_first_name,
    c.c_last_name
FROM 
    sales_summary ss
JOIN 
    warehouse w ON ss.w_warehouse_id = w.w_warehouse_id
JOIN 
    customer c ON c.c_current_addr_sk = (
        SELECT ca.ca_address_sk 
        FROM customer_address ca
        WHERE ca.ca_city = w.w_city
        LIMIT 1
    )
ORDER BY 
    ss.total_sales_amount DESC
LIMIT 10;
