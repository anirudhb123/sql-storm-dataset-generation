
WITH sales_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        s.s_store_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        store AS s ON ws.ws_ship_addr_sk = s.s_addr_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq, d.d_week_seq, s.s_store_name
),
top_stores AS (
    SELECT 
        s.s_store_name,
        SUM(ss.total_net_profit) AS store_total_net_profit
    FROM 
        sales_summary AS ss
    JOIN 
        store AS s ON ss.s_store_name = s.s_store_name
    GROUP BY 
        s.s_store_name
    ORDER BY 
        store_total_net_profit DESC
    LIMIT 5
)
SELECT 
    ts.s_store_name,
    ss.d_year,
    ss.d_week_seq,
    ss.total_quantity,
    ss.total_net_profit,
    ss.avg_net_paid
FROM 
    sales_summary AS ss
JOIN 
    top_stores AS ts ON ss.s_store_name = ts.s_store_name
ORDER BY 
    ts.store_total_net_profit DESC, ss.d_year, ss.d_week_seq;
