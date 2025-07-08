
WITH RECURSIVE Sales_Analysis AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_sales,
        SUM(ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
Monthly_Sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        sa.ws_item_sk,
        COALESCE(SUM(sa.total_sales), 0) AS monthly_total_sales,
        COALESCE(SUM(sa.total_revenue), 0) AS monthly_total_revenue
    FROM 
        date_dim d
    LEFT JOIN 
        Sales_Analysis sa ON d.d_date_sk = sa.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq, sa.ws_item_sk
)
SELECT 
    ms.d_year,
    ms.d_month_seq,
    i.i_item_id,
    i.i_item_desc,
    ms.monthly_total_sales,
    ms.monthly_total_revenue,
    CASE 
        WHEN ms.monthly_total_sales > 1000 THEN 'High Sales'
        WHEN ms.monthly_total_sales BETWEEN 500 AND 1000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category,
    (SELECT COUNT(*) FROM customer WHERE c_current_cdemo_sk IS NOT NULL) AS total_customers,
    (SELECT COUNT(*) FROM store WHERE s_number_employees > 10) AS active_stores
FROM 
    Monthly_Sales ms
JOIN 
    item i ON ms.ws_item_sk = i.i_item_sk
LEFT JOIN 
    (SELECT 
         ss_item_sk, 
         ss_store_sk 
     FROM 
         store_sales 
     ORDER BY 
         ss_net_paid DESC 
     QUALIFY ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY ss_net_paid DESC) = 1) s
ON 
    ms.ws_item_sk = s.ss_item_sk
WHERE 
    ms.d_year = 2022 AND ms.d_month_seq IN (1, 2, 3)
ORDER BY 
    ms.d_month_seq, ms.monthly_total_revenue DESC;
