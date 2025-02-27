
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        (SELECT 
            SUM(ws2.ws_net_profit) 
         FROM 
            web_sales ws2 
         WHERE 
            ws2.ws_sold_date_sk = ws.ws_sold_date_sk 
            AND ws2.ws_item_sk = ws.ws_item_sk
        ) AS total_profit_same_item
    FROM 
        web_sales ws
    WHERE 
        ws.ws_quantity > 0 
        AND ws.ws_net_profit IS NOT NULL
),
customer_return_stats AS (
    SELECT 
        wr.returning_customer_sk,
        COALESCE(SUM(wr.wr_return_quantity), 0) AS total_returns,
        COUNT(DISTINCT wr.wr_order_number) AS return_order_count,
        AVG(CASE WHEN wr.wr_return_amt > 0 THEN wr.wr_return_amt ELSE NULL END) AS avg_return_amt
    FROM 
        web_returns wr 
    GROUP BY 
        wr.returning_customer_sk
),
filtered_sales AS (
    SELECT 
        rs.web_site_sk,
        rs.ws_order_number,
        rs.rank_profit,
        rs.ws_quantity,
        rs.ws_net_profit,
        cs.c_customer_id
    FROM 
        ranked_sales rs
    JOIN 
        customer c ON rs.web_site_sk = c.c_current_addr_sk
    LEFT JOIN 
        customer_return_stats crs ON c.c_customer_sk = crs.returning_customer_sk
    WHERE 
        crs.total_returns < 5 
        OR crs.total_returns IS NULL
)
SELECT 
    f.web_site_sk,
    COUNT(DISTINCT f.ws_order_number) AS order_count,
    SUM(f.ws_net_profit) AS total_net_profit,
    STRING_AGG(DISTINCT f.c_customer_id) AS customer_ids,
    CASE 
        WHEN AVG(f.ws_quantity) > 10 THEN 'High Volume'
        WHEN AVG(f.ws_quantity) < 3 THEN 'Low Volume'
        ELSE 'Medium Volume'
    END AS volume_category
FROM 
    filtered_sales f
GROUP BY 
    f.web_site_sk
HAVING 
    SUM(f.ws_net_profit) > (SELECT AVG(ws_net_profit) FROM web_sales) 
ORDER BY 
    total_net_profit DESC;
