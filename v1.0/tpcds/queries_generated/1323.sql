
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
    GROUP BY 
        ws.web_site_id, ws.ws_order_number
),
top_sales AS (
    SELECT 
        web_site_id,
        ws_order_number,
        total_quantity,
        total_profit
    FROM 
        ranked_sales
    WHERE 
        profit_rank <= 10
),
store_sales_info AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_paid) AS net_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        ss.ss_store_sk
)
SELECT 
    s.s_store_name,
    s.s_city,
    s.s_state,
    COALESCE(t.total_quantity, 0) AS total_quantity,
    COALESCE(t.total_profit, 0.00) AS total_profit,
    si.net_sales,
    si.total_transactions,
    si.avg_sales_price,
    (CASE 
        WHEN si.total_transactions > 0 THEN (si.net_sales / si.total_transactions) 
        ELSE 0 
     END) AS average_transaction_value
FROM 
    store s
LEFT JOIN 
    top_sales t ON s.s_store_sk = t.ws_order_number
JOIN 
    store_sales_info si ON si.ss_store_sk = s.s_store_sk
WHERE 
    s.s_state IN ('CA', 'NY', 'TX')
ORDER BY 
    total_profit DESC, net_sales DESC;
