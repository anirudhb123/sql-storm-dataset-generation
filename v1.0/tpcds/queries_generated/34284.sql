
WITH RECURSIVE sales_cte AS (
    SELECT 
        w.w_warehouse_id,
        ss.s_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.net_paid,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY ss.s_sold_date_sk DESC) AS rn
    FROM 
        warehouse w
    JOIN 
        store_sales ss ON w.w_warehouse_sk = ss.ss_store_sk
    WHERE 
        ss.s_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim) - 30
),
top_sales AS (
    SELECT 
        w.warehouse_id,
        SUM(ss.net_paid) AS total_sales,
        AVG(ss.ss_quantity) AS avg_quantity,
        COUNT(ss.ss_item_sk) AS item_count
    FROM 
        sales_cte ss
    JOIN 
        warehouse w ON ss.w_warehouse_id = w.w_warehouse_id
    GROUP BY 
        w.warehouse_id
    HAVING 
        total_sales > (SELECT AVG(ss2.net_paid) FROM sales_cte ss2)
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank,
        CASE 
            WHEN cd.cd_purchase_estimate >= 10000 THEN 'High'
            WHEN cd.cd_purchase_estimate BETWEEN 5000 AND 9999 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_segment
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
final_report AS (
    SELECT 
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.purchase_segment,
        COALESCE(ts.total_sales, 0) AS total_sales
    FROM 
        customer_data cs
    LEFT JOIN 
        top_sales ts ON cs.c_customer_sk = ts.warehouse_id
    WHERE 
        cs.gender_rank <= 10
)
SELECT 
    fr.c_first_name,
    fr.c_last_name,
    fr.cd_gender,
    fr.purchase_segment,
    fr.total_sales,
    CASE 
        WHEN fr.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Made'
    END AS sales_status
FROM 
    final_report fr
ORDER BY 
    fr.total_sales DESC;
