
WITH customer_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        SUM(sr.return_amt) AS total_return_amount,
        SUM(sr.return_tax) AS total_return_tax,
        SUM(sr.return_quantity) AS total_return_quantity
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate
), 
sales_summary AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_items_sold
    FROM 
        web_sales ws
    GROUP BY 
        ws.bill_customer_sk
)
SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    cs.cd_purchase_estimate,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_orders, 0) AS total_orders,
    COALESCE(ss.total_items_sold, 0) AS total_items_sold,
    cs.total_returns,
    cs.total_return_amount,
    cs.total_return_tax,
    cs.total_return_quantity
FROM 
    customer_summary cs
LEFT JOIN 
    sales_summary ss ON cs.c_customer_id = ss.bill_customer_sk
WHERE 
    cs.cd_purchase_estimate > 1000
ORDER BY 
    total_sales DESC, cs.c_last_name ASC, cs.c_first_name ASC
LIMIT 50;
