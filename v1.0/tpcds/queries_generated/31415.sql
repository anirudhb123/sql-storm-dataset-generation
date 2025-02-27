
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_product_name, i_category, i_class, 0 AS level 
    FROM item 
    WHERE i_rec_start_date <= CURRENT_DATE AND i_rec_end_date >= CURRENT_DATE
    UNION ALL
    SELECT ih.i_item_sk, ih.i_product_name, ih.i_category, ih.i_class, ih.level + 1
    FROM ItemHierarchy ih
    JOIN item i ON i.i_item_sk = ih.i_item_sk
),
SalesSummary AS (
    SELECT 
        COALESCE(ws.bill_customer_sk, ss.customer_sk) AS customer_sk,
        SUM(ws.net_paid) AS total_web_sales,
        SUM(ss.net_paid) AS total_store_sales,
        COUNT(ws.order_number) AS web_order_count,
        COUNT(ss.ticket_number) AS store_order_count
    FROM web_sales ws
    FULL OUTER JOIN store_sales ss ON ws.bill_customer_sk = ss.customer_sk
    WHERE ws.sold_date_sk IS NOT NULL OR ss.sold_date_sk IS NOT NULL
    GROUP BY COALESCE(ws.bill_customer_sk, ss.customer_sk)
),
Demographics AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_income_band_sk, 
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FinalReport AS (
    SELECT 
        d.c_customer_sk,
        d.cd_gender,
        d.customer_value,
        ss.total_web_sales,
        ss.total_store_sales,
        ss.web_order_count,
        ss.store_order_count,
        CASE 
            WHEN total_web_sales > total_store_sales THEN 'Web Dominant'
            WHEN total_web_sales < total_store_sales THEN 'Store Dominant'
            ELSE 'Equal Sales'
        END AS sales_dominance
    FROM Demographics d
    LEFT JOIN SalesSummary ss ON d.c_customer_sk = ss.customer_sk
)
SELECT 
    fh.c_customer_sk,
    fh.cd_gender,
    fh.customer_value,
    fh.total_web_sales,
    fh.total_store_sales,
    fh.web_order_count,
    fh.store_order_count,
    fh.sales_dominance,
    ih.i_product_name,
    ih.i_category,
    ih.i_class,
    ROW_NUMBER() OVER (PARTITION BY fh.c_customer_sk ORDER BY total_web_sales DESC) AS rank
FROM FinalReport fh
JOIN ItemHierarchy ih ON ih.i_item_sk IN (SELECT i_item_sk FROM item WHERE i_product_name LIKE '%Gadget%')
WHERE fh.total_web_sales IS NOT NULL OR fh.total_store_sales IS NOT NULL
ORDER BY fh.c_customer_sk, rank;
