
WITH sales_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        c.c_city,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        d.d_year = 2023
        AND c.c_city IS NOT NULL
        AND i.i_current_price > 0
    GROUP BY 
        d.d_year, d.d_month_seq, c.c_city
),
city_ranking AS (
    SELECT 
        cs.d_year,
        cs.d_month_seq,
        cs.c_city,
        cs.total_sales,
        cs.order_count,
        cs.avg_net_profit,
        RANK() OVER (PARTITION BY cs.d_year, cs.d_month_seq ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        sales_summary cs
)
SELECT 
    cr.d_year,
    cr.d_month_seq,
    cr.c_city,
    cr.total_sales,
    cr.order_count,
    cr.avg_net_profit
FROM 
    city_ranking cr
WHERE 
    cr.sales_rank <= 10
ORDER BY 
    cr.d_year, cr.d_month_seq, cr.total_sales DESC;
