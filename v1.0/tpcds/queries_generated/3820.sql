
WITH ranked_sales AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        ws.ws_ship_mode_sk,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) as rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
store_sales_summary AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2021)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ss.ss_store_sk
),
customer_profit AS (
    SELECT 
        s.s_store_sk,
        SUM(ws.ws_net_profit) AS customer_net_profit
    FROM 
        store_sales ss
    JOIN 
        ranked_sales rs ON ss.ss_item_sk = rs.ws_item_sk
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        s.s_store_sk
)
SELECT 
    s.s_store_sk,
    s.s_store_name,
    COALESCE(ss.total_net_profit, 0) AS store_total_net_profit,
    COALESCE(cp.customer_net_profit, 0) AS customer_net_profit,
    CASE 
        WHEN COALESCE(ss.total_net_profit, 0) > 0 THEN 
            (COALESCE(cp.customer_net_profit, 0) / COALESCE(ss.total_net_profit, 1)) * 100 
        ELSE 0 
    END AS profit_percentage
FROM 
    store s
LEFT JOIN 
    store_sales_summary ss ON s.s_store_sk = ss.ss_store_sk
LEFT JOIN 
    customer_profit cp ON s.s_store_sk = cp.s_store_sk
WHERE 
    (ss.total_net_profit > 1000 OR cp.customer_net_profit IS NOT NULL)
ORDER BY 
    profit_percentage DESC
LIMIT 10;
