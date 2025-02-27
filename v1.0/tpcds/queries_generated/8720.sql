
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ca_state ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE 
        dd.d_year = 2022
        AND ws.ws_net_profit > 0
    GROUP BY 
        c.c_customer_id, ca.ca_state
),
TopCustomers AS (
    SELECT 
        customer_id,
        total_sales,
        sales_rank
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
)
SELECT 
    tc.customer_id,
    SUM(ws.ws_quantity) AS total_quantity,
    MAX(td.t_hour) AS peak_hour,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders
FROM 
    TopCustomers tc
JOIN 
    web_sales ws ON tc.customer_id = ws.ws_bill_customer_sk
JOIN 
    time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
GROUP BY 
    tc.customer_id
ORDER BY 
    total_quantity DESC;
