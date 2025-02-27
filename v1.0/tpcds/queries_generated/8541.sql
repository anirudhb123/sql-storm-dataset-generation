
WITH ReturnSummary AS (
    SELECT 
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_qty) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount,
        SUM(sr_return_tax) AS total_returned_tax,
        s_store_name,
        s_city,
        s_state
    FROM 
        store_returns sr
    JOIN 
        store s ON sr.s_store_sk = s.s_store_sk
    WHERE 
        sr_returned_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        s_store_name, s_city, s_state
),
SalesSummary AS (
    SELECT 
        s.s_store_name,
        s.s_city,
        s.s_state,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales w
    JOIN 
        store s ON w.ws_store_sk = s.s_store_sk
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        s.s_store_name, s.s_city, s.s_state
)
SELECT 
    r.s_store_name,
    r.s_city,
    r.s_state,
    r.total_returns,
    r.total_returned_quantity,
    r.total_returned_amount,
    r.total_returned_tax,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.total_net_profit, 0) AS total_net_profit
FROM 
    ReturnSummary r
LEFT JOIN 
    SalesSummary s ON r.s_store_name = s.s_store_name AND r.s_city = s.s_city AND r.s_state = s.s_state
ORDER BY 
    r.total_returns DESC, r.total_returned_amount DESC;
