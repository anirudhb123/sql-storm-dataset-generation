
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales AS ws
    JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND EXISTS (
            SELECT 1 
            FROM store s 
            WHERE s.s_store_sk = 
            (SELECT ss.ss_store_sk 
             FROM store_sales ss 
             WHERE ss.ss_item_sk = ws.ws_item_sk 
             ORDER BY ss.ss_sales_price DESC 
             LIMIT 1)
        )
    GROUP BY 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk
), PromotionData AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS promo_order_count
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk 
    WHERE 
        p.p_start_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d) 
        AND p.p_end_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d)
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
), FinalMetrics AS (
    SELECT 
        d.ws_sold_date_sk,
        d.ws_item_sk,
        d.total_quantity,
        d.total_sales,
        d.order_count,
        COALESCE(pd.promo_order_count, 0) AS promo_order_count
    FROM 
        SalesData d
    LEFT JOIN 
        PromotionData pd ON d.ws_item_sk = pd.p_promo_sk 
    WHERE 
        d.sales_rank <= 10
)
SELECT 
    f.ws_sold_date_sk,
    f.ws_item_sk,
    f.total_quantity,
    f.total_sales,
    f.order_count,
    f.promo_order_count,
    CASE 
        WHEN f.total_sales IS NULL THEN 'No Sales' 
        ELSE 'Sales Recorded' 
    END AS sales_status,
    CASE 
        WHEN f.promo_order_count > 0 THEN CONCAT('Promoted: ', (SELECT p.p_promo_name FROM PromotionData p WHERE p.promo_order_count = f.promo_order_count LIMIT 1))
        ELSE 'No Promotions'
    END AS promotion_info
FROM 
    FinalMetrics f
WHERE 
    f.total_quantity > (SELECT AVG(total_quantity) FROM SalesData)
ORDER BY 
    f.total_sales DESC NULLS LAST;
