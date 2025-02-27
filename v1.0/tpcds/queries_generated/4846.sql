
WITH ranked_sales AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        sum(COALESCE(ss.ss_net_profit, 0)) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ca.ca_city ORDER BY sum(COALESCE(ss.ss_net_profit, 0)) DESC) AS city_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, ca.ca_city
),
top_cities AS (
    SELECT 
        ca.ca_city,
        sum(total_net_profit) AS city_total_net_profit
    FROM 
        ranked_sales rs
    JOIN 
        customer_address ca ON rs.c_customer_id = ca.ca_address_sk
    WHERE 
        rs.city_rank <= 5
    GROUP BY 
        ca.ca_city
),
sales_by_week AS (
    SELECT 
        dd.d_year,
        dd.d_week_seq,
        sum(ws.ws_net_profit) AS week_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_year, dd.d_week_seq
)
SELECT 
    tc.ca_city,
    tc.city_total_net_profit,
    w.year,
    w.week_net_profit,
    CASE 
        WHEN w.week_net_profit IS NULL THEN 'No Profit'
        ELSE 'Profit Exists'
    END AS profit_status
FROM 
    top_cities tc
FULL OUTER JOIN 
    (SELECT 
         year,
         week_net_profit
     FROM 
         sales_by_week
     WHERE 
         week_net_profit > 10000) w ON tc.city_total_net_profit > 0
ORDER BY 
    tc.city_total_net_profit DESC, w.year DESC;
