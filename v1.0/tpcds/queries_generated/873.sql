
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        ws.web_site_sk, ws.web_site_id, ws.web_name
),
recent_returns AS (
    SELECT 
        wr.wr_web_page_sk,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk IN (
            SELECT d.d_date_sk
            FROM date_dim d
            WHERE d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
        )
    GROUP BY 
        wr.wr_web_page_sk
)
SELECT 
    r.web_site_id,
    r.web_name,
    r.total_net_profit,
    COALESCE(rr.total_returns, 0) AS total_returns,
    COALESCE(rr.total_return_amount, 0) AS total_return_amount,
    (r.total_net_profit - COALESCE(rr.total_return_amount, 0)) AS net_profit_after_returns
FROM 
    ranked_sales r
LEFT JOIN 
    recent_returns rr ON r.web_site_sk = rr.wr_web_page_sk
WHERE 
    r.rank = 1
ORDER BY 
    net_profit_after_returns DESC;
