
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales
),
average_sales AS (
    SELECT 
        ws_item_sk,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS gender,
        cd_marital_status,
        cd.education_status,
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        (SELECT 
            ws_bill_customer_sk AS customer_sk,
            ws_order_number AS order_id,
            SUM(ws_sales_price) AS ws_sales_price
         FROM 
            web_sales
         GROUP BY 
            ws_bill_customer_sk, ws_order_number) sales ON c.c_customer_sk = sales.customer_sk
    GROUP BY 
        c.c_customer_sk, cd_gender, cd_marital_status, cd.education_status
)
SELECT 
    ci.c_customer_sk,
    ci.gender,
    ci.cd_marital_status,
    ci.total_orders,
    ci.total_spent,
    COALESCE(rs.ws_sales_price, 0) AS max_web_sales_price,
    COALESCE(as.avg_sales_price, 0) AS avg_sales_price,
    CASE 
        WHEN ci.total_spent > 1000 THEN 'High Value'
        WHEN ci.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_segment
FROM 
    customer_info ci
LEFT JOIN 
    ranked_sales rs ON ci.c_customer_sk = rs.ws_item_sk AND rs.sales_rank = 1
LEFT JOIN 
    average_sales as ON ci.c_customer_sk = as.ws_item_sk
ORDER BY 
    ci.total_spent DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
