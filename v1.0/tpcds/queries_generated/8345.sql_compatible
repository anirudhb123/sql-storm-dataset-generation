
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 0
),
top_customers AS (
    SELECT 
        rc.c_customer_id,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        rc.cd_purchase_estimate,
        rc.cd_credit_rating
    FROM 
        ranked_customers rc
    WHERE 
        rc.rank <= 10
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    tc.cd_purchase_estimate,
    tc.cd_credit_rating,
    COALESCE(ss.total_net_profit, 0) AS total_net_profit,
    COALESCE(ss.order_count, 0) AS order_count
FROM 
    top_customers tc
LEFT JOIN 
    sales_summary ss ON tc.c_customer_id = ss.ws_bill_customer_sk
ORDER BY 
    total_net_profit DESC, 
    tc.c_first_name, 
    tc.c_last_name;
