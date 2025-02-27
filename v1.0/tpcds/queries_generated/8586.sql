
WITH total_sales AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_sales_price) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_by_customer AS (
    SELECT 
        ci.c_customer_id,
        ci.cd_gender,
        ci.cd_marital_status,
        ts.total_sold,
        ts.total_revenue,
        ts.total_orders
    FROM 
        total_sales ts
    JOIN 
        web_sales ws ON ts.i_item_id = ws.ws_item_sk
    JOIN 
        customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
)
SELECT 
    sbc.cd_gender,
    sbc.cd_marital_status,
    AVG(sbc.total_sold) AS avg_sales_per_customer,
    SUM(sbc.total_revenue) AS total_revenue,
    COUNT(DISTINCT sbc.c_customer_id) AS unique_customers
FROM 
    sales_by_customer sbc
GROUP BY 
    sbc.cd_gender, sbc.cd_marital_status
ORDER BY 
    avg_sales_per_customer DESC;
