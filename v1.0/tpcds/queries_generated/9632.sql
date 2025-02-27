
WITH RankedSales AS (
    SELECT 
        s_store_sk,
        ss_item_sk,
        SUM(ss_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_sales_price) DESC) AS rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 2451872 AND 2451880 -- Filtering for a specific date range
    GROUP BY 
        s_store_sk, ss_item_sk
),
TopSellingItems AS (
    SELECT 
        r.s_store_sk,
        i.i_item_id,
        i.i_product_name,
        r.total_sales
    FROM 
        RankedSales r
    JOIN 
        item i ON r.ss_item_sk = i.i_item_sk
    WHERE 
        r.rank <= 5 -- Top 5 items per store
),
StoreInfo AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        COUNT(DISTINCT tsi.i_item_id) AS top_items_count
    FROM 
        TopSellingItems tsi
    JOIN 
        store s ON tsi.s_store_sk = s.s_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name, s.s_city, s.s_state
),
SalesSummary AS (
    SELECT 
        si.s_store_sk,
        si.s_store_name,
        si.s_city,
        si.s_state,
        si.top_items_count,
        SUM(tsi.total_sales) AS total_revenue
    FROM 
        StoreInfo si
    JOIN 
        TopSellingItems tsi ON si.s_store_sk = tsi.s_store_sk
    GROUP BY 
        si.s_store_sk, si.s_store_name, si.s_city, si.s_state, si.top_items_count
)
SELECT 
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.top_items_count,
    s.total_revenue,
    s.total_revenue / NULLIF(s.top_items_count, 0) AS avg_revenue_per_top_item
FROM 
    SalesSummary s
ORDER BY 
    s.total_revenue DESC;
