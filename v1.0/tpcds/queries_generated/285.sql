
WITH top_customers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(ws.ws_net_paid) > 1000
),
high_value_items AS (
    SELECT 
        i.i_item_id,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = CURRENT_DATE - INTERVAL '1 year')
    GROUP BY 
        i.i_item_id
    HAVING 
        AVG(ws.ws_net_profit) > 25
),
customer_returns AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(tc.total_spent, 0) AS total_spent,
    COALESCE(tr.total_returns, 0) AS total_returns,
    hvi.order_count,
    hvi.avg_profit
FROM 
    customer c
LEFT JOIN 
    top_customers tc ON c.c_customer_id = tc.c_customer_id
LEFT JOIN 
    customer_returns tr ON c.c_customer_sk = tr.sr_customer_sk
LEFT JOIN 
    (SELECT 
         DISTINCT ws_bill_customer_sk,
         i.i_item_id,
         hvi.order_count,
         hvi.avg_profit
     FROM 
         high_value_items hvi
     JOIN 
         web_sales ws ON hvi.i_item_id = ws.ws_item_sk) hvi ON c.c_customer_sk = hvi.ws_bill_customer_sk
WHERE 
    c.c_first_name LIKE 'A%' 
    AND c.c_birth_year IS NOT NULL
ORDER BY 
    total_spent DESC, 
    total_returns DESC
LIMIT 10;
