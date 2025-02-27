
WITH aggregated_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        c.c_customer_id
),
ranked_sales AS (
    SELECT 
        customer_id,
        total_quantity,
        total_sales,
        avg_purchase_estimate,
        total_orders,
        RANK() OVER (ORDER BY total_sales DESC) as sales_rank
    FROM 
        aggregated_sales
)
SELECT 
    rs.customer_id,
    rs.total_quantity,
    rs.total_sales,
    rs.avg_purchase_estimate,
    rs.total_orders
FROM 
    ranked_sales rs
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.total_sales DESC;
