
WITH SalesSummary AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
        AND d.d_moy IN (6, 7)  -- June and July
    GROUP BY 
        w.w_warehouse_name
), CTE_Customer AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
        AND d.d_moy IN (6, 7)  -- June and July
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
), CustomerInsights AS (
    SELECT 
        cd.gender,
        cd.marital_status,
        cd.education_status,
        COUNT(DISTINCT ci.c_customer_id) AS customer_count,
        AVG(ci.total_spent) AS avg_spent
    FROM 
        CTE_Customer ci
    JOIN 
        customer_demographics cd ON ci.cd_gender = cd.cd_gender
    GROUP BY 
        cd.gender, cd.marital_status, cd.education_status
)
SELECT 
    ss.warehouse_name,
    cs.gender,
    cs.marital_status,
    cs.education_status,
    ss.total_quantity_sold,
    ss.total_sales,
    cs.customer_count,
    cs.avg_spent
FROM 
    SalesSummary ss
JOIN 
    CustomerInsights cs ON ss.total_quantity_sold > 100
ORDER BY 
    ss.total_sales DESC, cs.customer_count DESC;
