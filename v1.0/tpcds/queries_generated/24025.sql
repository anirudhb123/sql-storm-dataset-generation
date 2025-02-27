
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) as rank_sales,
        COUNT(*) OVER (PARTITION BY ws_item_sk) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 2000
),
SalesSummary AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_sales_price) AS total_revenue,
        AVG(rs.ws_sales_price) AS avg_price,
        COUNT(*) AS sale_count
    FROM 
        RankedSales rs
    WHERE 
        rs.rank_sales = 1
    GROUP BY 
        rs.ws_item_sk
),
StoreSalesDetails AS (
    SELECT 
        ss.ss_item_sk,
        ss_store_sk,
        SUM(ss.ss_sales_price) AS store_revenue,
        COUNT(*) AS store_transaction_count
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk > 1500
    GROUP BY 
        ss.ss_item_sk, ss.ss_store_sk
)
SELECT 
    ss.store_revenue,
    ss.store_transaction_count,
    CASE 
        WHEN ss.store_transaction_count = 0 THEN 'No transactions'
        ELSE TO_CHAR((ss.store_revenue / NULLIF(ss.store_transaction_count, 0)), 'FM$999,999.00')
    END AS avg_store_revenue_per_transaction,
    s.ws_item_sk,
    ss.total_revenue,
    s.sale_count,
    COALESCE(SUM(sd.store_revenue), 0) AS total_store_revenue
FROM 
    SalesSummary s
LEFT JOIN 
    StoreSalesDetails ss ON s.ws_item_sk = ss.ss_item_sk
GROUP BY 
    ss.ss_store_sk, s.ws_item_sk, ss.store_revenue, ss.store_transaction_count, s.total_revenue, s.sale_count
ORDER BY 
    1 DESC, 2 DESC;
