WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        COUNT(ws_item_sk) AS item_count
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2001-01-01') 
                            AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2001-12-31')
    GROUP BY 
        ws_bill_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cs.total_sales,
        cs.order_count,
        cs.item_count,
        COALESCE(cd.cd_dep_count, 0) AS dependents,
        COALESCE(cd.cd_credit_rating, 'Unknown') AS credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        sales_summary cs ON c.c_customer_sk = cs.ws_bill_customer_sk
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.total_sales,
    ci.order_count,
    ci.item_count,
    ci.dependents,
    ci.credit_rating
FROM 
    customer_info ci
WHERE 
    ci.total_sales IS NOT NULL 
    AND (ci.total_sales > (SELECT AVG(total_sales) FROM sales_summary) OR ci.cd_gender = 'F')
ORDER BY 
    ci.total_sales DESC
LIMIT 50;