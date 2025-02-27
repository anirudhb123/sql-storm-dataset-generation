
WITH RECURSIVE sales_data AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_sales,
        SUM(ss_net_paid) AS total_revenue,
        CAST(NULL AS DECIMAL(10,2)) AS cumulative_revenue
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 2450811 AND 2454846
    GROUP BY 
        ss_store_sk, ss_item_sk
    UNION ALL
    SELECT 
        sd.ss_store_sk,
        sd.ss_item_sk,
        sd.total_sales,
        sd.total_revenue,
        SUM(sd.total_revenue) OVER (PARTITION BY sd.ss_store_sk ORDER BY sd.total_revenue ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue
    FROM 
        sales_data sd
    WHERE 
        EXISTS (
            SELECT 1
            FROM store s
            WHERE s.s_store_sk = sd.ss_store_sk AND s.s_number_employees > 100
        )
)
SELECT 
    ca.city AS store_city,
    w.warehouse_name,
    sd.ss_item_sk,
    sd.total_sales,
    sd.total_revenue,
    sd.cumulative_revenue,
    CASE 
        WHEN sd.total_revenue IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM 
    sales_data sd
JOIN 
    store s ON sd.ss_store_sk = s.s_store_sk
JOIN 
    warehouse w ON s.s_store_sk = w.w_warehouse_sk
JOIN 
    customer_address ca ON s.s_store_sk = ca.ca_address_sk
LEFT OUTER JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (
        SELECT c.c_current_cdemo_sk 
        FROM customer c 
        WHERE c.c_customer_sk = (
            SELECT TOP 1 ss.ss_customer_sk
            FROM store_sales ss
            WHERE ss.ss_item_sk = sd.ss_item_sk
            ORDER BY ss.ss_net_profit DESC
        )
    )
WHERE 
    w.w_warehouse_sq_ft > 10000
    AND (sd.total_sales > 0 OR sd.total_revenue IS NOT NULL)
ORDER BY 
    store_city,
    total_revenue DESC
LIMIT 100;
