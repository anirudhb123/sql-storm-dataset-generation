
WITH customer_details AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state 
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
customer_sales AS (
    SELECT 
        cd.c_customer_id,
        cd.c_first_name,
        cd.c_last_name,
        cs_total.total_sales,
        cs_total.order_count,
        ROW_NUMBER() OVER (PARTITION BY cd.c_customer_id ORDER BY cs_total.total_sales DESC) AS sales_rank
    FROM 
        customer_details cd
    LEFT JOIN 
        (SELECT 
            ws_bill_customer_sk AS customer_sk,
            SUM(ws_sales_price) AS total_sales,
            COUNT(ws_order_number) AS order_count
         FROM 
            web_sales 
         GROUP BY 
            ws_bill_customer_sk) cs_total ON cd.c_customer_id = cs_total.customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    c.ca_city,
    c.ca_state,
    COALESCE(cs.total_sales, 0) AS total_sales,
    COALESCE(cs.order_count, 0) AS order_count
FROM 
    customer_details c
LEFT JOIN 
    customer_sales cs ON c.c_customer_id = cs.c_customer_id
WHERE 
    cs.sales_rank = 1
ORDER BY 
    total_sales DESC
LIMIT 100;
