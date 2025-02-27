
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        0 AS depth 
    FROM 
        customer 
    WHERE 
        c_preferred_cust_flag = 'Y'
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        ch.depth + 1 AS depth 
    FROM 
        customer AS c
    JOIN 
        CustomerHierarchy AS ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
MonthlySales AS (
    SELECT 
        d.d_year, 
        d.d_month_seq, 
        SUM(ws.net_profit) AS total_net_profit 
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq
),
SalesWithRanks AS (
    SELECT 
        ms.d_year,
        ms.d_month_seq,
        ms.total_net_profit,
        RANK() OVER (PARTITION BY ms.d_year ORDER BY ms.total_net_profit DESC) AS profit_rank
    FROM 
        MonthlySales AS ms
)
SELECT 
    ch.c_first_name, 
    ch.c_last_name, 
    sr.total_net_loss,
    CASE 
        WHEN sr.total_net_loss IS NULL THEN 'No Loss'
        ELSE 'Loss Detected'
    END AS loss_status,
    CASE 
        WHEN sr.total_net_loss > 1000 THEN 'High Loss'
        ELSE 'Low Loss'
    END AS loss_category,
    STRING_AGG(ws.ws_item_sk::text, ', ') AS purchased_items
FROM 
    CustomerHierarchy AS ch
LEFT JOIN 
    store_returns AS sr ON ch.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    web_sales AS ws ON ws.ws_bill_customer_sk = ch.c_customer_sk
LEFT JOIN 
    SalesWithRanks AS r ON r.d_year = EXTRACT(YEAR FROM CURRENT_DATE) AND r.d_month_seq = EXTRACT(MONTH FROM CURRENT_DATE)
GROUP BY 
    ch.c_first_name, ch.c_last_name, sr.total_net_loss, r.profit_rank
HAVING 
    COUNT(ws.ws_item_sk) > 3 
    OR (sr.total_net_loss < 500 AND r.profit_rank <= 10)
ORDER BY 
    ch.c_last_name ASC, ch.c_first_name ASC;
