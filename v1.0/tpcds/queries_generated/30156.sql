
WITH RECURSIVE top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
    ORDER BY 
        total_profit DESC
    LIMIT 10
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer_demographics cd
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(cd.cd_gender, 'Unknown') AS gender,
    COALESCE(cd.cd_marital_status, 'Not Specified') AS marital_status,
    CASE 
        WHEN cd.cd_purchase_estimate IS NULL THEN 0 
        ELSE cd.cd_purchase_estimate 
    END AS purchase_estimate,
    tc.total_profit
FROM 
    top_customers tc
LEFT JOIN 
    customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk 
WHERE 
    total_profit > (SELECT AVG(total_profit) FROM top_customers) 
    AND (cd.cd_marital_status IS NULL OR cd.cd_marital_status IN ('S', 'M'))
ORDER BY 
    total_profit DESC, 
    tc.c_last_name ASC;

WITH item_sales AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_net_profit) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
top_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(is.total_sales, 0) AS total_sales,
        is.total_orders,
        RANK() OVER (ORDER BY COALESCE(is.total_sales, 0) DESC) AS sales_rank
    FROM 
        item i
    LEFT JOIN 
        item_sales is ON i.i_item_sk = is.ws_item_sk
)
SELECT 
    *
FROM 
    top_items
WHERE 
    sales_rank <= 5 OR total_sales > (
        SELECT 
            AVG(total_sales) 
        FROM 
            item_sales
    )
ORDER BY 
    total_sales DESC;
