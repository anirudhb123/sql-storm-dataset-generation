
WITH aggregated_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 10000 AND 10500
    GROUP BY 
        ws_bill_customer_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        as.total_quantity,
        as.total_sales,
        as.avg_net_profit
    FROM 
        customer_info ci
    JOIN 
        aggregated_sales as ON ci.c_customer_sk = as.ws_bill_customer_sk
    WHERE 
        as.total_sales > 1000
    ORDER BY 
        as.total_sales DESC
    LIMIT 10
)
SELECT 
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    COUNT(*) AS customer_count,
    SUM(tc.total_quantity) AS total_quantity,
    SUM(tc.total_sales) AS total_sales,
    AVG(tc.avg_net_profit) AS avg_net_profit
FROM 
    top_customers tc
GROUP BY 
    tc.cd_gender, 
    tc.cd_marital_status, 
    tc.cd_education_status
ORDER BY 
    total_sales DESC;
