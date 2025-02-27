
WITH RECURSIVE sales_data AS (
    SELECT 
        c.c_customer_id,
        c.c_birth_year,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rnk
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
    GROUP BY 
        c.c_customer_id, c.c_birth_year
    HAVING 
        SUM(ws.ws_net_profit) > 10000
),
recent_sales AS (
    SELECT 
        sd.c_customer_id,
        sd.total_profit,
        d.d_year,
        d.d_month_seq
    FROM 
        sales_data sd
    JOIN 
        date_dim d ON d.d_date_sk = (
            SELECT MAX(ws.ws_sold_date_sk)
            FROM web_sales ws
            WHERE ws.ws_bill_customer_sk = sd.c_customer_id
        )
    WHERE 
        sd.rnk < 5
)
SELECT 
    r.c_customer_id,
    r.d_year,
    r.d_month_seq,
    COALESCE(r.total_profit, 0) AS profit,
    COUNT(DISTINCT r.d_year || '-' || r.d_month_seq) OVER (PARTITION BY r.c_customer_id) AS month_count
FROM 
    recent_sales r
RIGHT OUTER JOIN 
    customer c ON r.c_customer_id = c.c_customer_id
WHERE 
    c.c_birth_year < 1980 AND 
    c.c_current_cdemo_sk IS NOT NULL
ORDER BY 
    r.total_profit DESC, c.c_customer_id;
