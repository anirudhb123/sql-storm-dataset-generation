
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
best_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    WHERE 
        cs.total_sales > 10000
),
return_summary AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amount) AS total_return_amount
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_item_sk
),
combined_sales AS (
    SELECT 
        bs.c_customer_sk,
        bs.total_sales,
        bs.order_count,
        COALESCE(rs.return_count, 0) AS return_count,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount
    FROM 
        best_customers bs
    LEFT JOIN 
        return_summary rs ON bs.c_customer_sk = rs.sr_item_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_sales,
    cs.order_count,
    cs.return_count,
    cs.total_return_amount,
    (cs.total_sales - cs.total_return_amount) AS net_profit
FROM 
    combined_sales cs
WHERE 
    cs.return_count < 5
ORDER BY 
    net_profit DESC
LIMIT 10
;
