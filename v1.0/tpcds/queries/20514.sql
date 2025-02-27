
WITH RECURSIVE sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rn
    FROM 
        customer c 
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
        AND ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
return_summary AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns sr
    WHERE 
        sr.sr_customer_sk IS NOT NULL
    GROUP BY 
        sr.sr_customer_sk
), 
combined_sales AS (
    SELECT 
        s.c_customer_sk,
        s.c_first_name,
        s.c_last_name,
        s.total_quantity,
        s.total_net_paid,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_returned_amount, 0) AS total_returned_amount,
        (s.total_net_paid - COALESCE(r.total_returned_amount, 0)) AS net_profit_after_returns
    FROM 
        sales_summary s
    LEFT JOIN 
        return_summary r ON s.c_customer_sk = r.sr_customer_sk
)
SELECT 
    cs.c_first_name || ' ' || cs.c_last_name AS customer_name,
    cs.total_quantity,
    cs.total_net_paid,
    cs.total_returns,
    cs.total_returned_amount,
    CASE 
        WHEN cs.net_profit_after_returns > 0 THEN 'Profitable'
        WHEN cs.net_profit_after_returns < 0 THEN 'Loss'
        ELSE 'Break Even'
    END AS profit_status,
    (SELECT AVG(total_net_paid) FROM sales_summary WHERE rn <= 10) AS avg_top_customers
FROM 
    combined_sales cs
WHERE 
    cs.total_quantity > 10
ORDER BY 
    cs.net_profit_after_returns DESC
LIMIT 25 
OFFSET (SELECT COUNT(*) FROM combined_sales) / 2;
