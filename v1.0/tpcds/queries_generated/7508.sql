
WITH sales_summary AS (
    SELECT 
        d.d_year AS sales_year,
        c.c_gender AS customer_gender,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS average_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year, c.c_gender
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory i
    JOIN 
        warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ss.sales_year,
    ss.customer_gender,
    ss.total_quantity,
    ss.total_sales,
    ss.average_profit,
    ws.total_inventory
FROM 
    sales_summary ss
JOIN 
    warehouse_summary ws ON ss.sales_year = 2023
ORDER BY 
    ss.sales_year, ss.customer_gender;
