
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year >= 1980
),

total_sales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk
),

high_profit_sites AS (
    SELECT 
        ts.web_site_sk,
        ts.total_net_profit
    FROM 
        total_sales ts
    WHERE 
        ts.total_net_profit > (
            SELECT AVG(total_net_profit) FROM total_sales
        )
)

SELECT 
    r.web_site_id,
    r.ws_order_number,
    r.ws_net_profit,
    ts.total_net_profit
FROM 
    ranked_sales r
LEFT JOIN 
    high_profit_sites ts ON r.web_site_id = ts.web_site_sk
WHERE 
    r.rank <= 5
ORDER BY 
    r.web_site_id, r.ws_net_profit DESC;

