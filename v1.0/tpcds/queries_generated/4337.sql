
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_ship_date_sk) AS last_order_date,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_first_name IS NOT NULL
    GROUP BY 
        c.c_customer_id
),
ReturnedSales AS (
    SELECT 
        wr.wr_returning_customer_sk,
        COUNT(DISTINCT wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returning_customer_sk
),
SalesRanking AS (
    SELECT 
        cs.c_customer_id,
        cs.total_web_sales,
        cs.total_orders,
        cs.last_order_date,
        cs.avg_order_value,
        RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    sr.c_customer_id,
    sr.total_web_sales,
    sr.total_orders,
    sr.last_order_date,
    sr.avg_order_value,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN sr.total_web_sales > 1000 THEN 'High Value'
        WHEN sr.total_web_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    SalesRanking sr
LEFT JOIN 
    ReturnedSales rs ON sr.c_customer_id = rs.wr_returning_customer_sk
WHERE 
    sr.sales_rank <= 100
ORDER BY 
    sr.total_web_sales DESC;
