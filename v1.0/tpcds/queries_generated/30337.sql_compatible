
WITH RECURSIVE sales_summary AS (
    SELECT 
        w.warehouse_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY w.warehouse_id ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        w.w_warehouse_id IS NOT NULL
    GROUP BY 
        w.warehouse_id
), customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_income_band_sk, cd.cd_marital_status
), ranked_customers AS (
    SELECT 
        ci.full_name,
        ci.total_orders,
        ci.cd_gender,
        ib.ib_income_band_sk,
        RANK() OVER (ORDER BY ci.total_orders DESC) AS order_rank
    FROM 
        customer_info ci
    LEFT JOIN 
        income_band ib ON ci.cd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ci.total_orders > 5
)
SELECT 
    ss.warehouse_id,
    ss.total_sales,
    rc.full_name,
    rc.total_orders,
    rc.cd_gender
FROM 
    sales_summary ss
JOIN 
    ranked_customers rc ON ss.sales_rank <= 10
WHERE 
    (rc.cd_gender = 'M' AND ss.total_sales > 1000) 
    OR (rc.cd_gender = 'F' AND ss.total_sales > 1500)
ORDER BY 
    ss.total_sales DESC, rc.total_orders DESC;
