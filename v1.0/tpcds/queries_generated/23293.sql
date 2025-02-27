
WITH order_summary AS (
    SELECT 
        ss.store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM 
        store_sales ss
    WHERE 
        ss_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        ss.store_sk
),
top_stores AS (
    SELECT 
        os.store_sk,
        os.total_sales,
        os.total_quantity,
        os.total_transactions,
        DENSE_RANK() OVER (ORDER BY os.total_sales DESC) AS sales_rank
    FROM 
        order_summary os
    WHERE 
        os.total_sales > (SELECT AVG(total_sales) FROM order_summary)
),
promotions_data AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        p.p_start_date_sk,
        p.p_end_date_sk,
        COUNT(DISTINCT ws.ws_order_number) AS promo_sales_count
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk 
    GROUP BY 
        p.p_promo_sk, p.p_promo_name, p.p_start_date_sk, p.p_end_date_sk
),
aggregate_data AS (
    SELECT 
        ts.sales_rank,
        COALESCE(pd.promo_sales_count, 0) AS promo_sales_count,
        ts.total_sales,
        ts.total_quantity,
        ROUND(ts.total_transactions / NULLIF(ts.total_quantity, 0), 2) AS avg_quantity_per_transaction
    FROM 
        top_stores ts
    LEFT JOIN 
        promotions_data pd ON ts.store_sk = (SELECT wd.ws_store_sk FROM web_sales wd LIMIT 1 OFFSET (ts.sales_rank - 1))
),
final_report AS (
    SELECT 
        ad.sales_rank,
        ad.promo_sales_count,
        ad.total_sales,
        ad.total_quantity,
        ad.avg_quantity_per_transaction,
        CASE 
            WHEN ad.avg_quantity_per_transaction IS NULL THEN 'Unknown'
            WHEN ad.avg_quantity_per_transaction > 10 THEN 'High'
            WHEN ad.avg_quantity_per_transaction BETWEEN 5 AND 10 THEN 'Medium'
            ELSE 'Low'
        END AS transaction_quality,
        STRING_AGG(DISTINCT CONCAT('Promo: ', p.p_promo_name), '; ' ORDER BY p.p_promo_name) AS promotions_used
    FROM 
        aggregate_data ad
    LEFT JOIN 
        promotions_data p ON p.promo_sales_count > 0
    GROUP BY 
        ad.sales_rank, ad.promo_sales_count, ad.total_sales, ad.total_quantity, ad.avg_quantity_per_transaction
)
SELECT 
    sales_rank,
    promo_sales_count,
    total_sales,
    total_quantity,
    avg_quantity_per_transaction,
    transaction_quality,
    COALESCE(promotions_used, 'None') AS promotions_used
FROM 
    final_report
WHERE 
    sales_rank <= 10
ORDER BY 
    sales_rank;
