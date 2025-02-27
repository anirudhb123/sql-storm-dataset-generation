
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT sr.ticket_number) as total_returns,
        SUM(sr.return_amt) as total_return_amount,
        AVG(sr.return_quantity) as avg_return_quantity,
        COUNT(DISTINCT ws.order_number) as total_orders,
        SUM(ws.ext_sales_price) as total_sales,
        AVG(ws.net_paid) as avg_order_value
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' AND cd.cd_marital_status = 'M' -- Filtering for married females
        AND c.c_birth_year >= 1980 -- Birth year filter
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
SalesSummary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.net_paid) AS total_sales_amount,
        COUNT(DISTINCT ws.order_number) AS total_sales_count
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    cs.c_customer_id,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    cs.total_returns,
    cs.total_return_amount,
    cs.avg_return_quantity,
    cs.total_orders,
    cs.total_sales,
    cs.avg_order_value,
    ss.total_sales_amount,
    ss.total_sales_count
FROM 
    CustomerStats cs
JOIN 
    SalesSummary ss ON cs.total_sales > ss.total_sales_amount * 0.1 -- Join based on significant sales
ORDER BY 
    cs.total_sales DESC, cs.avg_order_value DESC;
