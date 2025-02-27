
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales 
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ss_store_sk, ss_item_sk
    HAVING 
        SUM(ss_net_paid) > 100
),
TopStores AS (
    SELECT 
        s_store_sk,
        s_store_name,
        w_city,
        w_state,
        SUM(total_sales) AS cumulative_sales
    FROM 
        SalesCTE 
    JOIN 
        store s ON SalesCTE.ss_store_sk = s.s_store_sk
    JOIN 
        warehouse w ON s.s_company_id = w.w_warehouse_sk
    WHERE 
        sales_rank <= 5
    GROUP BY 
        s_store_sk, s_store_name, w_city, w_state
),
PromoImpact AS (
    SELECT 
        p.p_promo_id,
        SUM(ws_net_paid) AS promo_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales 
    JOIN 
        promotion p ON ws_promo_sk = p.p_promo_sk
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        p.p_promo_id
),
FinalReport AS (
    SELECT 
        ts.s_store_name,
        ts.w_city,
        ts.w_state,
        ts.cumulative_sales,
        pi.promo_sales,
        pi.order_count
    FROM 
        TopStores ts
    FULL OUTER JOIN 
        PromoImpact pi ON ts.s_store_sk = pi.p_promo_id
)
SELECT 
    f.*, 
    CASE 
        WHEN f.cumulative_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_indicator,
    CASE 
        WHEN f.promo_sales IS NULL THEN 'No Promotions'
        ELSE 'Promotional Activity'
    END AS promo_indicator
FROM 
    FinalReport f
ORDER BY 
    cumulative_sales DESC NULLS LAST, 
    promo_sales DESC NULLS FIRST;
