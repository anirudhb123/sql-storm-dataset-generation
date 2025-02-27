
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2021-01-01')
    GROUP BY ws.web_site_sk, ws.web_site_id, ws.ws_sold_date_sk
), CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        cm.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_order_value,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns
    FROM customer c
    LEFT JOIN customer_demographics cm ON c.c_current_cdemo_sk = cm.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, cm.cd_gender
), WebsitePerformance AS (
    SELECT 
        r.web_site_id,
        r.total_sales,
        cs.total_orders,
        cs.avg_order_value,
        cs.total_returns,
        CASE
            WHEN cs.total_orders > 0 THEN (r.total_sales / cs.total_orders)
            ELSE NULL
        END AS sales_per_order
    FROM RankedSales r
    LEFT JOIN CustomerSummary cs ON cs.total_orders > 0
    WHERE r.sales_rank = 1
)
SELECT 
    wp.web_site_id,
    wp.total_sales,
    wp.total_orders,
    wp.avg_order_value,
    wp.total_returns,
    wp.sales_per_order,
    CASE 
        WHEN wp.total_returns IS NULL OR wp.total_sales IS NULL THEN 'Data Insufficient'
        ELSE 'Data Available'
    END AS data_availability
FROM WebsitePerformance wp
ORDER BY wp.total_sales DESC;
