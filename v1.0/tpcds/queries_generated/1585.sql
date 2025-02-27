
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2023
        AND d.d_month_seq BETWEEN 1 AND 6
    )
    GROUP BY ws.web_site_id
),
customer_with_demographics AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_first_name) AS rn
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cs.web_site_id,
    cs.total_sales,
    cs.avg_profit,
    cs.order_count,
    CONCAT(ws.web_name, ' - ', COALESCE(cd.cd_marital_status, 'Unknown')) AS customer_info,
    i.i_product_name,
    CASE
        WHEN cs.total_sales > 10000 THEN 'High'
        WHEN cs.total_sales BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM sales_summary cs
JOIN web_site ws ON cs.web_site_id = ws.web_site_id
LEFT JOIN customer_with_demographics cd ON cd.rn = 1
LEFT JOIN item i ON cs.order_count = (
    SELECT COUNT(*)
    FROM web_sales
    WHERE ws_item_sk = i.i_item_sk
    ) 
WHERE cs.sales_rank <= 5
ORDER BY cs.total_sales DESC, customer_info;
