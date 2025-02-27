
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2400 AND 2450
        AND i.i_current_price IS NOT NULL
),
top_web_sales AS (
    SELECT 
        web_site_sk, 
        web_order_number, 
        web_item_sk, 
        web_quantity, 
        web_sales_price, 
        web_net_profit 
    FROM 
        ranked_sales 
    WHERE 
        profit_rank <= 10
),
store_sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
),
sales_comparison AS (
    SELECT 
        tws.web_site_sk,
        ts.total_net_profit,
        ts.total_transactions,
        tws.web_sales_price
    FROM 
        top_web_sales tws
    LEFT JOIN 
        store_sales_summary ts ON tws.web_site_sk = ts.ss_store_sk
)

SELECT 
    sc.web_site_sk,
    COALESCE(sc.total_net_profit, 0) as total_store_profit,
    SUM(sc.web_sales_price * sc.total_transactions) AS calculated_profit,
    CASE 
        WHEN sc.total_net_profit IS NULL THEN 'No Store Sales'
        ELSE 'Sales Available'
    END AS sales_status
FROM 
    sales_comparison sc
GROUP BY 
    sc.web_site_sk, sc.total_net_profit
HAVING 
    calculated_profit > 1000
ORDER BY 
    calculated_profit DESC;
