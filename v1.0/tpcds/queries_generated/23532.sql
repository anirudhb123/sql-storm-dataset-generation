
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
high_value_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM customer_sales)
),
return_stats AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT wr.wr_order_number) AS return_order_count
    FROM 
        web_returns wr
    WHERE 
        wr.wr_return_quantity > 0
    GROUP BY 
        wr.wr_returning_customer_sk
),
combined_stats AS (
    SELECT 
        hvc.c_customer_id,
        hvc.total_sales,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        hvc.order_count,
        rs.return_order_count
    FROM 
        high_value_customers hvc
    LEFT JOIN 
        return_stats rs ON hvc.c_customer_id = rs.wr_returning_customer_sk
)
SELECT 
    c.customer_id,
    cs.total_sales,
    cs.order_count,
    cs.avg_sales_price,
    rs.total_return_amount,
    rs.return_order_count,
    CASE 
        WHEN cs.total_sales IS NULL THEN 'No Sales'
        WHEN cs.total_sales > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    combined_stats cs
LEFT JOIN 
    customer c ON cs.c_customer_id = c.c_customer_id
ORDER BY 
    CASE 
        WHEN cs.total_sales IS NULL THEN 1
        ELSE 0
    END, 
    cs.total_sales DESC;
