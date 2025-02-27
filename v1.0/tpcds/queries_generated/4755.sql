
WITH customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        ci.c_customer_sk, 
        ci.c_first_name, 
        ci.c_last_name, 
        ci.cd_gender, 
        ci.cd_marital_status 
    FROM 
        customer_info ci
    WHERE 
        ci.rn <= 5
),
item_sales AS (
    SELECT 
        wi.ws_item_sk, 
        SUM(wi.ws_net_paid_inc_tax) AS total_sales 
    FROM 
        web_sales wi
    WHERE 
        wi.ws_sold_date_sk BETWEEN 1 AND 100
    GROUP BY 
        wi.ws_item_sk
),
customer_sales AS (
    SELECT 
        ci.c_customer_sk,
        SUM(COALESCE(ws.ws_net_paid_inc_tax, 0)) AS total_spending
    FROM 
        top_customers ci
    LEFT JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ci.c_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_spending,
    CASE
        WHEN cs.total_spending >= 1000 THEN 'High Value'
        WHEN cs.total_spending >= 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    is.total_sales,
    i.i_item_desc
FROM 
    customer_sales cs
LEFT JOIN 
    item_sales is ON cs.c_customer_sk = is.ws_item_sk
LEFT JOIN 
    item i ON is.ws_item_sk = i.i_item_sk
WHERE 
    is.total_sales IS NOT NULL
ORDER BY 
    cs.total_spending DESC, customer_value;
