
WITH RECURSIVE sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS dense_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
high_value_customers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cs.order_count
    FROM 
        sales_summary cs
    JOIN 
        customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        cs.total_sales IS NOT NULL 
        AND cs.sales_rank <= 10 
        AND cd.cd_marital_status = 'M'
)
SELECT 
    hvc.c_customer_id,
    hvc.total_sales,
    hvc.order_count,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_returns,
    COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returned_items
FROM 
    high_value_customers hvc
LEFT JOIN 
    store_returns sr ON sr.sr_customer_sk = hvc.c_customer_id
GROUP BY 
    hvc.c_customer_id, hvc.total_sales, hvc.order_count
HAVING 
    (hvc.total_sales - COALESCE(SUM(sr.sr_return_amt), 0)) > 1000
ORDER BY 
    hvc.total_sales DESC
LIMIT 5;
