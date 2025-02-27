
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
), 
high_value_customers AS (
    SELECT 
        rc.c_customer_id,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_purchase_estimate
    FROM 
        ranked_customers rc
    WHERE 
        rc.purchase_rank <= 10
), 
sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        c.c_customer_id,
        w.w_warehouse_id,
        d.d_year
    FROM 
        web_sales ws
    JOIN 
        high_value_customers c ON ws.ws_bill_customer_sk = c.c_customer_id
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
)
SELECT 
    d.d_year,
    COUNT(DISTINCT sd.ws_order_number) AS total_orders,
    SUM(sd.ws_sales_price * sd.ws_quantity) AS total_revenue,
    AVG(sd.ws_sales_price) AS average_sales_price,
    SUM(sd.ws_quantity) AS total_units_sold
FROM 
    sales_data sd
GROUP BY 
    d.d_year
ORDER BY 
    d.d_year DESC;
