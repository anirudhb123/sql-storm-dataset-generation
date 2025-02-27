
WITH SalesSummary AS (
    SELECT 
        w.w_warehouse_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        AVG(ws.ws_quantity) AS avg_quantity_per_order,
        RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS revenue_rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        w.w_warehouse_name
), 
TopWarehouses AS (
    SELECT 
        w_warehouse_name 
    FROM 
        SalesSummary 
    WHERE 
        revenue_rank <= 5
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_net_paid_inc_tax) AS total_revenue_from_top_warehouses,
    COALESCE((SELECT AVG(ws2.ws_net_paid_inc_tax)
               FROM web_sales ws2
               JOIN store s ON ws2.ws_ship_customer_sk = s.s_store_sk
               WHERE s.s_city = ca.ca_city AND s.s_state = ca.ca_state), 0) AS avg_revenue_city_state
FROM 
    customer_address ca
LEFT JOIN 
    web_sales ws ON ca.ca_address_sk = ws.ws_bill_addr_sk
WHERE 
    EXISTS (SELECT 1 FROM TopWarehouses tw WHERE tw.w_warehouse_name = (SELECT w.w_warehouse_name FROM warehouse w JOIN web_sales ws2 ON w.w_warehouse_sk = ws2.ws_warehouse_sk WHERE ws2.ws_ship_addr_sk = ca.ca_address_sk))
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    total_revenue_from_top_warehouses DESC;
