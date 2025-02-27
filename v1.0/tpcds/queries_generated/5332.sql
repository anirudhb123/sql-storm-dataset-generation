
WITH sales_summary AS (
    SELECT 
        c.c_customer_id AS customer_id,
        d.d_year AS sales_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        c.c_customer_id, d.d_year
),
customer_summary AS (
    SELECT 
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        AVG(ss.total_sales) AS avg_sales,
        AVG(ss.order_count) AS avg_orders,
        AVG(ss.total_quantity) AS avg_quantity,
        AVG(ss.total_discount) AS avg_discount
    FROM
        sales_summary ss
    JOIN 
        customer_demographics cd ON ss.customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    gender,
    marital_status,
    COUNT(*) AS customer_count,
    AVG(avg_sales) AS avg_sales,
    AVG(avg_orders) AS avg_orders,
    AVG(avg_quantity) AS avg_quantity,
    AVG(avg_discount) AS avg_discount
FROM
    customer_summary
GROUP BY 
    gender, marital_status
ORDER BY 
    gender, marital_status;
