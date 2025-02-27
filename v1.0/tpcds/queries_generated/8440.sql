
WITH CustomerMetrics AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT w.ws_order_number) AS total_web_orders,
        SUM(w.ws_sales_price) AS total_web_sales,
        COUNT(DISTINCT ss.ticket_number) AS total_store_orders,
        SUM(ss.ss_sales_price) AS total_store_sales,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
SalesStats AS (
    SELECT 
        cm.c_customer_id,
        cm.cd_gender,
        cm.cd_marital_status,
        cm.cd_education_status,
        cm.total_web_orders,
        cm.total_web_sales,
        cm.total_store_orders,
        cm.total_store_sales,
        cm.total_returns,
        cm.avg_purchase_estimate,
        CASE 
            WHEN cm.total_web_sales > cm.total_store_sales THEN 'Web Dominant' 
            WHEN cm.total_store_sales > cm.total_web_sales THEN 'Store Dominant' 
            ELSE 'Balanced' 
        END AS sales_channel_dominance
    FROM CustomerMetrics cm
)
SELECT 
    s.cd_gender,
    s.cd_marital_status,
    s.cd_education_status,
    AVG(s.total_web_sales) AS avg_web_sales,
    AVG(s.total_store_sales) AS avg_store_sales,
    COUNT(CASE WHEN s.sales_channel_dominance = 'Web Dominant' THEN 1 END) AS web_dominant_count,
    COUNT(CASE WHEN s.sales_channel_dominance = 'Store Dominant' THEN 1 END) AS store_dominant_count,
    COUNT(CASE WHEN s.sales_channel_dominance = 'Balanced' THEN 1 END) AS balanced_count
FROM SalesStats s
GROUP BY s.cd_gender, s.cd_marital_status, s.cd_education_status
ORDER BY avg_web_sales DESC;
