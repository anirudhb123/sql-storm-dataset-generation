
WITH RankedSales AS (
    SELECT 
        ss.store_sk,
        ss.item_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER(PARTITION BY ss.store_sk ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.store_sk = s.s_store_sk
    GROUP BY 
        ss.store_sk, ss.item_sk
),
TopStores AS (
    SELECT 
        r.store_sk, 
        s.s_store_name,
        r.item_sk,
        r.total_quantity,
        r.total_sales
    FROM 
        RankedSales r
    JOIN 
        store s ON r.store_sk = s.s_store_sk
    WHERE 
        r.sales_rank <= 5
),
SalesWithPromotion AS (
    SELECT 
        ts.store_sk,
        ts.item_sk,
        ts.total_quantity,
        ts.total_sales,
        p.p_promo_name,
        p.p_discount_active
    FROM 
        TopStores ts
    LEFT JOIN 
        promotion p ON ts.item_sk = p.p_item_sk
    WHERE 
        p.p_discount_active = 'Y' OR p.p_discount_active IS NULL
)
SELECT 
    ts.s_store_name,
    i.i_item_desc,
    swp.total_quantity,
    swp.total_sales,
    COALESCE(swp.p_promo_name, 'No Promotion') AS promotion,
    CASE 
        WHEN swp.p_discount_active IS NULL THEN 'No Discount'
        ELSE 'Active Discount'
    END AS discount_status
FROM 
    SalesWithPromotion swp
JOIN 
    item i ON swp.item_sk = i.i_item_sk
JOIN 
    store s ON swp.store_sk = s.s_store_sk
ORDER BY 
    swp.total_sales DESC
LIMIT 10;
