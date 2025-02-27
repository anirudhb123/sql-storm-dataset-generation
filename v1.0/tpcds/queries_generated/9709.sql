
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
top_customers AS (
    SELECT 
        r.c_customer_id,
        r.c_first_name,
        r.c_last_name,
        r.cd_gender,
        r.cd_marital_status,
        r.cd_purchase_estimate
    FROM 
        ranked_customers r
    WHERE 
        r.rank <= 10
),
sales_summary AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_bill_customer_sk IN (SELECT DISTINCT c.c_customer_sk FROM customer c WHERE c.c_customer_id IN (SELECT c_customer_id FROM top_customers))
    GROUP BY 
        ws.bill_customer_sk
),
customer_sales AS (
    SELECT 
        tc.c_customer_id,
        tc.c_first_name,
        tc.c_last_name,
        tc.cd_gender,
        tc.cd_marital_status,
        ss.total_sales,
        ss.order_count
    FROM 
        top_customers tc
    LEFT JOIN 
        sales_summary ss ON ss.bill_customer_sk = (
            SELECT c_customer_sk FROM customer WHERE c_customer_id = tc.c_customer_id
        )
)
SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_sales,
    cs.order_count,
    CASE 
        WHEN cs.total_sales IS NULL THEN 'No Sales'
        WHEN cs.total_sales > 5000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    customer_sales cs
ORDER BY 
    cs.total_sales DESC;
