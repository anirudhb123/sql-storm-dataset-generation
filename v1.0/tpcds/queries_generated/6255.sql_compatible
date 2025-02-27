
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_list_price) AS avg_item_price,
        SUM(ws_ext_discount_amt) AS total_discount,
        d_year
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_year >= 2021
    GROUP BY 
        ws_bill_customer_sk, d_year
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cs.total_sales,
        cs.total_orders,
        cs.avg_item_price,
        cs.total_discount
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_summary cs ON c.c_customer_sk = cs.customer_sk
)
SELECT 
    AVG(total_sales) AS avg_sales,
    COUNT(DISTINCT customer_sk) AS num_customers,
    cd_gender,
    cd_marital_status,
    cd_credit_rating
FROM 
    customer_info
GROUP BY 
    cd_gender, cd_marital_status, cd_credit_rating
ORDER BY 
    avg_sales DESC;
