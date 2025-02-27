
WITH sales_summary AS (
    SELECT 
        ws.sold_date_sk,
        ws.ship_mode_sk,
        SUM(ws.net_paid) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        AVG(ws.net_profit) AS average_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.item_sk = i.item_sk
    JOIN 
        customer c ON ws.bill_customer_sk = c.customer_sk
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
    WHERE 
        cd.gender = 'F'
          AND ws.sold_date_sk BETWEEN 2400 AND 2500
          AND i.current_price > 20.00
    GROUP BY 
        ws.sold_date_sk,
        ws.ship_mode_sk
),
ranked_sales AS (
    SELECT 
        ss.sold_date_sk,
        ss.ship_mode_sk,
        ss.total_sales,
        ss.total_orders,
        ss.average_profit,
        RANK() OVER (PARTITION BY ss.sold_date_sk ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        sales_summary ss
)
SELECT 
    d.d_date AS sale_date,
    sm.sm_type AS shipping_mode,
    rs.total_sales,
    rs.total_orders,
    rs.average_profit,
    rs.sales_rank
FROM 
    ranked_sales rs
JOIN 
    date_dim d ON rs.sold_date_sk = d.date_sk
JOIN 
    ship_mode sm ON rs.ship_mode_sk = sm.ship_mode_sk
WHERE 
    rs.sales_rank <= 5
ORDER BY 
    sale_date,
    sales_rank;
