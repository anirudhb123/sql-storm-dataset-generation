
WITH summary_sales AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS average_profit,
        DENSE_RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_bill_customer_sk
),
customer_details AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name,
        cd.cd_gender,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.c_customer_id,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_credit_rating,
    ss.total_sales,
    ss.total_orders,
    ss.average_profit,
    ss.sales_rank
FROM 
    customer_details cd
LEFT JOIN 
    summary_sales ss ON cd.c_customer_id = ss.customer_id
WHERE 
    ss.sales_rank <= 100
ORDER BY 
    ss.total_sales DESC;
