
WITH RECURSIVE sales_recursive AS (
    SELECT 
        ss_store_sk, 
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_sales,
        1 AS level
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk
    
    UNION ALL
    
    SELECT 
        sr.ss_store_sk, 
        sr.total_profit + sr2.ss_net_profit AS total_profit,
        sr.total_sales + 1 AS total_sales,
        sr.level + 1
    FROM 
        sales_recursive sr
    JOIN 
        store_sales sr2 ON sr.ss_store_sk = sr2.ss_store_sk
    WHERE 
        sr2.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023) 
        AND sr2.ss_ticket_number > (sr.total_sales * 100)
)

SELECT 
    s.s_store_id,
    s.s_store_name,
    c.cd_gender,
    SUM(ws.ws_net_profit) OVER (PARTITION BY s.s_store_sk) AS total_ws_profit,
    i.i_item_desc,
    AVG(ws.ws_sales_price) OVER (PARTITION BY ws.ws_ship_mode_sk) AS avg_ws_price,
    COALESCE(SUM(sr.total_profit), 0) AS recursive_total_profit
FROM 
    store s
LEFT JOIN 
    web_sales ws ON s.s_store_sk = ws.ws_store_sk
LEFT JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN 
    sales_recursive sr ON s.s_store_sk = sr.ss_store_sk
WHERE 
    s.s_store_sk IN (SELECT DISTINCT ss_store_sk FROM store_sales)
    AND (ws.ws_net_paid_inc_tax IS NOT NULL OR ws.ws_net_paid_inc_ship IS NULL)
GROUP BY 
    s.s_store_id, s.s_store_name, c.cd_gender, i.i_item_desc
ORDER BY 
    total_ws_profit DESC, recursive_total_profit ASC
LIMIT 100;
