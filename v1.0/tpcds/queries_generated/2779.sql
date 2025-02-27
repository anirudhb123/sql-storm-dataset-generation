
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
), 
sales_analysis AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_quantity,
        cs.total_sales,
        CASE 
            WHEN cs.total_sales > 5000 THEN 'High Value'
            WHEN cs.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value,
        COUNT(ws.ws_item_sk) OVER (PARTITION BY cs.c_customer_sk) AS item_count,
        ROW_NUMBER() OVER (PARTITION BY cs.customer_value ORDER BY cs.total_sales DESC) AS value_rank
    FROM 
        customer_summary cs
)
SELECT 
    sa.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    sa.total_quantity,
    sa.total_sales,
    sa.customer_value,
    sa.item_count
FROM 
    sales_analysis sa
JOIN 
    customer_summary cs ON sa.c_customer_sk = cs.c_customer_sk
WHERE 
    cs.sales_rank <= 10
ORDER BY 
    sa.customer_value, sa.total_sales DESC
LIMIT 50;

-- Perform outer join for missing sales records 
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    COALESCE(SUM(ws.ws_sales_price), 0) AS total_sales,
    COUNT(ws.ws_item_sk) AS sales_count
FROM 
    customer c 
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name
HAVING 
    total_sales > 100
ORDER BY 
    total_sales DESC;
