
WITH RECURSIVE sales_summary AS (
    SELECT 
        s.s_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        MAX(ss_sold_date_sk) AS last_sold_date
    FROM store_sales s
    JOIN store str ON s.s_store_sk = str.s_store_sk
    LEFT JOIN web_sales ws ON ws.ws_ship_date_sk = s.ss_sold_date_sk 
        AND ws.ws_item_sk = s.ss_item_sk
    LEFT JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
    WHERE str.s_state IS NOT NULL
    GROUP BY s.s_store_sk
),
demographic_summary AS (
    SELECT 
        c.c_customer_sk,
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) as rnk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd_purchase_estimate IS NOT NULL
)
SELECT 
    ss.s_store_sk,
    ss.total_sales,
    ss.last_sold_date,
    ds.cd_gender,
    ds.cd_marital_status,
    SUM(ds.cd_purchase_estimate) AS total_estimates,
    CASE 
        WHEN SUM(ds.cd_purchase_estimate) IS NULL THEN 'No Data'
        WHEN SUM(ds.cd_purchase_estimate) < 5000 THEN 'Low'
        WHEN SUM(ds.cd_purchase_estimate) BETWEEN 5000 AND 15000 THEN 'Medium'
        ELSE 'High'
    END AS income_band
FROM sales_summary ss
FULL OUTER JOIN demographic_summary ds ON ss.s_store_sk = ds.cd_demo_sk
WHERE ds.rnk <= 10 OR ds.cd_gender IS NULL
GROUP BY ss.s_store_sk, ds.cd_gender, ds.cd_marital_status, ss.total_sales, ss.last_sold_date
HAVING COUNT(ss.s_store_sk) > 1 OR ds.cd_gender = 'F'
ORDER BY total_sales DESC NULLS LAST
LIMIT 100 OFFSET 0;
