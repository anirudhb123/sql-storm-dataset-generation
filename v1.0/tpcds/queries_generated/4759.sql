
WITH top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_net_paid) > 1000
),
sales_per_item AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        item AS i
    JOIN 
        web_sales AS ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
),
returns_summary AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns
    FROM 
        catalog_returns AS cr
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(s.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    CASE 
        WHEN COALESCE(s.total_sales, 0) = 0 THEN NULL 
        ELSE (COALESCE(r.total_returns, 0) * 100.0) / COALESCE(s.total_sales, 0) 
    END AS return_rate_percentage,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent
FROM 
    item AS i
LEFT JOIN 
    sales_per_item AS s ON i.i_item_sk = s.i_item_sk
LEFT JOIN 
    returns_summary AS r ON i.i_item_sk = r.cr_item_sk
CROSS JOIN 
    top_customers AS tc
WHERE 
    i.i_current_price > 20.00
ORDER BY 
    return_rate_percentage DESC, total_sales DESC;
