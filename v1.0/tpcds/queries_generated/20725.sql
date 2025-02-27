
WITH sales_ranked AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 AND 
                                   (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
store_sales_summary AS (
    SELECT 
        ss.s_store_sk,
        SUM(ss.ss_net_profit) AS total_store_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2021) 
        AND (ss.ss_quantity * ss.ss_sales_price) > 0
    GROUP BY 
        ss.s_store_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_returns,
        COUNT(DISTINCT sr.ticket_number) AS return_count
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
   HAVING 
        COUNT(DISTINCT sr.ticket_number) > 1
),
combined_summary AS (
    SELECT 
        s_store.s_store_sk,
        s_store.s_store_name,
        ss.total_store_profit,
        cr.total_returns,
        cr.return_count
    FROM 
        store_sales_summary ss
    JOIN 
        store s_store ON ss.s_store_sk = s_store.s_store_sk
    LEFT JOIN 
        customer_summary cr ON ss.s_store_sk = cr.c_customer_sk
)
SELECT 
    ws_rank.web_name,
    cs.s_store_name,
    cs.total_store_profit,
    cs.total_returns,
    cs.return_count,
    COALESCE(ws_rank.total_net_profit, 0) AS web_total_net_profit
FROM 
    sales_ranked ws_rank
FULL OUTER JOIN 
    combined_summary cs ON ws_rank.web_site_sk = cs.s_store_sk
WHERE 
    (cs.total_store_profit IS NOT NULL OR ws_rank.total_net_profit IS NOT NULL)
    AND (cs.return_count > 5 OR ws_rank.profit_rank = 1)
ORDER BY 
    COALESCE(ws_rank.total_net_profit, 0) DESC,
    COALESCE(cs.total_store_profit, 0) DESC;
