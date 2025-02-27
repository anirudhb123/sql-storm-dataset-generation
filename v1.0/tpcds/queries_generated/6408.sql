
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
AggregateData AS (
    SELECT 
        ci.c_customer_id,
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_orders, 0) AS total_orders,
        COALESCE(sd.total_discount, 0) AS total_discount,
        DENSE_RANK() OVER (ORDER BY COALESCE(sd.total_sales, 0) DESC) AS sales_rank
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesData sd ON ci.c_customer_id = sd.ws_bill_customer_sk
)
SELECT 
    ag.c_customer_id,
    ag.total_quantity,
    ag.total_sales,
    ag.total_orders,
    ag.total_discount,
    ag.sales_rank,
    CASE 
        WHEN ag.total_sales > 5000 THEN 'High Value' 
        WHEN ag.total_sales > 1000 THEN 'Medium Value' 
        ELSE 'Low Value' 
    END AS customer_value_category
FROM 
    AggregateData ag
WHERE 
    ag.sales_rank <= 10
ORDER BY 
    ag.sales_rank;
