
WITH ranked_sales AS (
    SELECT 
        ws.ship_mode_sk,
        ws.item_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.ship_mode_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ship_mode_sk, ws.item_sk
),
sales_summary AS (
    SELECT 
        rs.ship_mode_sk,
        rs.item_sk,
        rs.total_sales,
        sm.sm_type,
        CASE 
            WHEN rs.total_sales IS NULL THEN 'No Sales'
            ELSE 'Sales Made'
        END AS sales_status
    FROM 
        ranked_sales rs
    LEFT JOIN 
        ship_mode sm ON rs.ship_mode_sk = sm.sm_ship_mode_sk
)
SELECT 
    css.ship_mode_sk,
    css.sm_type,
    css.item_sk,
    COALESCE(css.total_sales, 0) AS total_sales,
    CASE 
        WHEN css.sales_status = 'Sales Made' THEN 'Reached Sales Threshold'
        ELSE 'Below Threshold'
    END AS sales_threshold_status,
    COUNT(DISTINCT ws.bill_customer_sk) AS unique_customers,
    AVG(cd.purchase_estimate) AS avg_purchase_estimate
FROM 
    sales_summary css
LEFT JOIN 
    web_sales ws ON css.item_sk = ws.item_sk AND css.ship_mode_sk = ws.ship_mode_sk
LEFT JOIN 
    customer_demographics cd ON ws.bill_cdemo_sk = cd.cd_demo_sk
WHERE 
    (css.total_sales > 1000 OR css.sales_status = 'No Sales')
GROUP BY 
    css.ship_mode_sk, css.sm_type, css.item_sk, css.total_sales, css.sales_status
HAVING 
    AVG(cd.purchase_estimate) IS NOT NULL
ORDER BY 
    total_sales DESC;
