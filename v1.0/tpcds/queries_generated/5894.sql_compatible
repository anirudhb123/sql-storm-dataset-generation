
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_paid) AS total_net_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS average_profit,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_moy BETWEEN 1 AND 6 
        AND cd.cd_gender = 'F' 
    GROUP BY 
        ws.web_site_id
),
TopSales AS (
    SELECT 
        web_site_id, 
        total_net_sales,
        total_orders,
        average_profit,
        total_quantity,
        RANK() OVER (ORDER BY total_net_sales DESC) AS sales_rank
    FROM 
        SalesData
)

SELECT 
    t.web_site_id,
    t.total_net_sales,
    t.total_orders,
    t.average_profit,
    t.total_quantity,
    t.sales_rank,
    w.w_warehouse_name,
    w.w_city,
    w.w_state
FROM 
    TopSales t
JOIN 
    warehouse w ON t.web_site_id = w.w_warehouse_id
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_net_sales DESC;
