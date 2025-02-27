
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_paid) AS avg_spent,
        CASE 
            WHEN COUNT(DISTINCT ws_order_number) > 5 THEN 'Frequent'
            ELSE 'Occasional'
        END AS customer_type
    FROM 
        customer c
    JOIN 
        web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
top_items AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_paid) AS total_revenue
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_quantity) > 1000
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.order_count,
    cs.avg_spent,
    ti.total_sold,
    ti.total_revenue
FROM 
    customer_summary cs
LEFT JOIN 
    top_items ti ON cs.c_customer_sk IN (
        SELECT 
            ws_bill_customer_sk
        FROM 
            web_sales
        WHERE 
            ws_item_sk = ti.ws_item_sk
    )
WHERE 
    cs.customer_type = 'Frequent'
ORDER BY 
    cs.avg_spent DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
