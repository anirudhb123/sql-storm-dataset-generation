
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(d.d_date) AS last_sale_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
TopProducts AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        sd.total_quantity,
        sd.total_revenue,
        sd.total_orders,
        sd.last_sale_date
    FROM 
        SalesData sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    ORDER BY 
        sd.total_revenue DESC
    LIMIT 10
)
SELECT 
    tp.i_item_id,
    tp.i_item_desc,
    tp.total_quantity,
    tp.total_revenue,
    tp.total_orders,
    tp.last_sale_date,
    cc.cc_name AS call_center_name,
    ca.ca_city AS customer_city,
    count(DISTINCT c.c_customer_sk) AS distinct_customers
FROM 
    TopProducts tp
JOIN 
    store_sales ss ON tp.ws_item_sk = ss.ss_item_sk
JOIN 
    call_center cc ON ss.ss_call_center_sk = cc.cc_call_center_sk
JOIN 
    customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
    tp.i_item_id, tp.i_item_desc, tp.total_quantity, 
    tp.total_revenue, tp.total_orders, tp.last_sale_date, 
    cc.cc_name, ca.ca_city
ORDER BY 
    tp.total_revenue DESC;
