
WITH sales_summary AS (
    SELECT 
        ws.bill_customer_sk,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        CASE 
            WHEN SUM(ws_sales_price) > 0 THEN SUM(ws_net_profit) / SUM(ws_sales_price)
            ELSE 0
        END AS profit_margin
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
        AND ws.sold_date_sk BETWEEN 2459580 AND 2459650
    GROUP BY 
        ws.bill_customer_sk
),
top_customers AS (
    SELECT
        bill_customer_sk,
        total_orders,
        total_quantity,
        total_sales,
        total_discount,
        profit_margin,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    tc.bill_customer_sk,
    tc.total_orders,
    tc.total_quantity,
    tc.total_sales,
    tc.total_discount,
    tc.profit_margin
FROM 
    top_customers tc
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
