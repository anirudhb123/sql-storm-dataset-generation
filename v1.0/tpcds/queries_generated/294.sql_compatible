
WITH sales_data AS (
    SELECT 
        w.warehouse_name,
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY w.warehouse_name ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.warehouse_name, ws.ws_sold_date_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
high_value_customers AS (
    SELECT 
        ci.*, 
        CASE 
            WHEN ci.total_orders > 10 THEN 'Gold'
            WHEN ci.total_orders BETWEEN 5 AND 10 THEN 'Silver'
            ELSE 'Bronze'
        END AS customer_tier
    FROM 
        customer_info ci
    WHERE 
        ci.avg_order_value IS NOT NULL AND ci.avg_order_value > 50
),
return_data AS (
    SELECT
        sr.returned_date_sk,
        SUM(sr.return_amt) AS total_return_amt,
        COUNT(sr.returned_date_sk) AS return_count
    FROM 
        store_returns sr
    GROUP BY 
        sr.returned_date_sk
)
SELECT 
    sd.warehouse_name,
    sd.ws_sold_date_sk,
    sd.total_sales,
    sd.order_count,
    r.total_return_amt,
    r.return_count,
    hvc.customer_tier
FROM 
    sales_data sd
LEFT JOIN 
    return_data r ON sd.ws_sold_date_sk = r.returned_date_sk
LEFT JOIN 
    high_value_customers hvc ON sd.order_count > 5
WHERE 
    sd.sales_rank <= 5
ORDER BY 
    sd.total_sales DESC, sd.ws_sold_date_sk DESC;
