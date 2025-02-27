
WITH sales_summary AS (
    SELECT 
        d.d_year, 
        d.d_month_seq, 
        d.d_quarter_seq, 
        c.cc_class, 
        SUM(ws.ws_net_profit) AS total_profit, 
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq, d.d_quarter_seq, c.cc_class
),
aggregate_summary AS (
    SELECT 
        d_year, 
        d_month_seq, 
        d_quarter_seq, 
        cc_class,
        total_profit,
        total_orders,
        RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank,
        RANK() OVER (PARTITION BY d_year ORDER BY total_orders DESC) AS order_rank
    FROM 
        sales_summary
)
SELECT 
    d_year, 
    d_month_seq, 
    d_quarter_seq, 
    cc_class, 
    total_profit, 
    total_orders
FROM 
    aggregate_summary
WHERE 
    profit_rank <= 5 OR order_rank <= 5
ORDER BY 
    d_year, profit_rank, order_rank;
