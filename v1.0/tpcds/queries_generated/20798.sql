
WITH RankedSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ss.ss_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(ss.ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        warehouse w ON s.s_company_id = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
TopSales AS (
    SELECT 
        warehouse_id,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
),
CustomerProfiles AS (
    SELECT 
        c.c_customer_id,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS gender,
        COALESCE(cd.cd_dep_count, 0) AS dep_count,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_dep_count
),
SalesSummary AS (
    SELECT 
        tp.warehouse_id,
        cp.gender,
        SUM(tp.total_sales) AS warehouse_sales,
        AVG(cp.dep_count) AS avg_dep_count,
        COUNT(DISTINCT cp.c_customer_id) AS unique_customers
    FROM 
        TopSales tp
    FULL OUTER JOIN 
        CustomerProfiles cp ON tp.warehouse_id = (SELECT DISTINCT w.w_warehouse_id FROM warehouse w)
    GROUP BY 
        tp.warehouse_id, cp.gender
)
SELECT 
    s.warehouse_id,
    s.warehouse_sales,
    s.avg_dep_count,
    s.unique_customers,
    NULLIF(s.warehouse_sales, 0) AS adjusted_sales,
    CASE 
        WHEN s.avg_dep_count IS NOT NULL THEN s.unique_customers / NULLIF(s.avg_dep_count, 0)
        ELSE NULL
    END AS customer_to_dep_ratio,
    COALESCE(MAX(cp.gender), 'No Gender Info') AS predominant_gender
FROM 
    SalesSummary s
LEFT JOIN 
    CustomerProfiles cp ON s.unique_customers = cp.total_orders
GROUP BY 
    s.warehouse_id, s.warehouse_sales, s.avg_dep_count, s.unique_customers
HAVING 
    (s.warehouse_sales > 10000 OR s.warehouse_id IS NULL)
ORDER BY 
    s.warehouse_sales DESC;
